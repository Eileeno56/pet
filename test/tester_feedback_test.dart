import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';
import 'package:petreminder_user/models/care_plan.dart';
import 'package:petreminder_user/models/feeding_schedule.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:petreminder_user/providers/pet_care_providers.dart';
import 'package:petreminder_user/repositories/auth_repository.dart';
import 'package:petreminder_user/repositories/user_repository.dart';
import 'package:petreminder_user/repositories/feeding_history_repository.dart';
import 'package:petreminder_user/repositories/feeding_schedule_repository.dart';
import 'package:petreminder_user/repositories/pet_repository.dart';
import 'package:petreminder_user/services/auth_service.dart';
import 'package:petreminder_user/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockRepository extends Mock implements AuthRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockUsers extends Mock implements UserRepository {}

Pet get max => Pet(
  id: 'p',
  name: 'Max',
  species: 'Perro',
  breed: '',
  age: 2,
  description: '',
  photoUrl: null,
  createdAt: DateTime(2026),
);

Future<void> seedCare(FakeFirebaseFirestore db) async {
  await db.doc('users/u/pets/p').set({
    'name': 'Max',
    'species': 'Perro',
    'age': 2,
    'createdAt': Timestamp.now(),
  });
}

void main() {
  test('nombres rechazan números y símbolos, conservan letras acentuadas', () {
    for (final name in ['Ana123', '984848diidken&', 'Max🐾', 'Juan_2']) {
      expect(InputValidators.requiredName(name), isNotNull);
      expect(InputValidators.petName(name), isNotNull);
    }
    for (final name in ['María José', 'Dulce Sugey', 'Ñoño', 'Max']) {
      expect(InputValidators.requiredName(name), isNull);
      expect(InputValidators.petName(name), isNull);
    }
  });
  test(
    'registro usa frases largas sin impedir acceso con contraseñas anteriores',
    () {
      expect(InputValidators.newPassword('eei3i3i3ii33'), isNotNull);
      expect(InputValidators.newPassword('passwordpassword'), isNotNull);
      expect(InputValidators.newPassword('aaaaaaaaaaaaaaa'), isNotNull);
      expect(InputValidators.newPassword('               '), isNotNull);
      expect(InputValidators.newPassword('***************'), isNotNull);
      expect(InputValidators.newPassword('Mi conejo salta al sol!'), isNull);
      expect(
        InputValidators.newPassword('Una frase larga sin símbolos'),
        isNull,
      );
      expect(InputValidators.password('123456'), isNull);
    },
  );
  test(
    'correo inexistente se traduce al mismo error genérico que credencial incorrecta',
    () async {
      final service = MockAuthService();
      final repository = AuthRepository(service, MockUsers());
      for (final code in [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
      ]) {
        when(
          () => service.signInWithEmail(
            email: 'nadie@example.com',
            password: '123456',
          ),
        ).thenThrow(FirebaseAuthException(code: code));
        await expectLater(
          repository.signInWithEmail(
            email: 'nadie@example.com',
            password: '123456',
          ),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.message,
              'mensaje',
              'No fue posible iniciar sesión. Revisa tus datos e inténtalo de nuevo.',
            ),
          ),
        );
      }
    },
  );
  test('tiempo de espera libera el controlador y permite reintentar', () async {
    final repo = MockRepository();
    final pending = Completer<void>();
    when(
      () =>
          repo.signInWithEmail(email: 'nadie@example.com', password: '123456'),
    ).thenAnswer((_) => pending.future);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        authTimeoutProvider.overrideWithValue(const Duration(milliseconds: 10)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final controller = container.read(authControllerProvider.notifier);
    final operation = controller.signInWithEmail(
      email: 'nadie@example.com',
      password: '123456',
    );
    expect(container.read(authControllerProvider).isLoading, isTrue);
    expect(await operation, isFalse);
    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(
      (container.read(authControllerProvider).error as AuthFailure).code,
      'timeout',
    );
    pending.complete();
    await pumpEventQueue();
    expect(container.read(authControllerProvider).hasError, isTrue);
    when(
      () =>
          repo.signInWithEmail(email: 'nadie@example.com', password: '123456'),
    ).thenAnswer((_) async {});
    expect(
      await controller.signInWithEmail(
        email: 'nadie@example.com',
        password: '123456',
      ),
      isTrue,
    );
  });
  test(
    'horarios guardan días y detalles y no crean comidas en días excluidos',
    () async {
      final db = FakeFirebaseFirestore();
      await seedCare(db);
      final today = DateTime.now().weekday;
      final otherDay = today % 7 + 1;
      final schedules = FeedingScheduleRepository(db);
      final id = await schedules.createSchedule(
        'u',
        'p',
        '08:00',
        label: 'Desayuno',
        foodType: 'Croquetas',
        weekdays: [otherDay],
      );
      final schedule = FeedingSchedule.fromDocument(
        await db.doc('users/u/pets/p/feedingSchedules/$id').get(),
      );
      expect(schedule.label, 'Desayuno');
      expect(schedule.weekdays, [otherDay]);
      final history = FeedingHistoryRepository(db);
      await history.ensureTodayForPet('u', max);
      expect(
        (await db.collection('users/u/feedingHistory').get()).docs,
        isEmpty,
      );
      await schedules.updateTime(
        'u',
        'p',
        id,
        '09:00',
        label: 'Comida',
        weekdays: [today],
      );
      await history.ensureTodayForPet('u', max);
      await history.ensureTodayForPet('u', max);
      expect(
        (await db.collection('users/u/feedingHistory').get()).docs.length,
        1,
      );
      await history.markAsFed(
        userId: 'u',
        pet: max,
        scheduleId: id,
        scheduledTime: '09:00',
        grams: 40,
        food: 'Croquetas',
      );
      await history.markAsFed(
        userId: 'u',
        pet: max,
        scheduleId: id,
        scheduledTime: '09:00',
        grams: 80,
        food: 'Croquetas',
      );
      expect(
        (await db.collection('users/u/feedingHistory').get()).docs.single
            .data()['grams'],
        40,
      );
      await expectLater(
        schedules.updateTime('u', 'p', id, '09:00', weekdays: []),
        throwsA(isA<Exception>()),
      );
    },
  );
  test(
    'recurrencia semanal respeta el día y el aviso previo puede cruzar medianoche',
    () {
      tz_data.initializeTimeZones();
      final location = tz.getLocation('America/Mexico_City');
      final now = tz.TZDateTime(location, 2026, 10, 26, 0, 0); // lunes
      final next = NotificationService.nextOccurrence(
        time: '00:03',
        weekday: 1,
        now: now,
      );
      expect(next.day, 26);
      expect(next.weekday, 1);
      final before = next.subtract(const Duration(minutes: 5));
      expect(before.weekday, 7);
      expect(before.hour, 23);
      expect(before.minute, 58);
      final nextWeek = NotificationService.nextOccurrence(
        time: '00:03',
        weekday: 1,
        now: next,
      );
      expect(nextWeek.difference(next).inDays, 7);
    },
  );
  test(
    'comidas manuales suman gramos, y borrar mascota limpia todo su cuidado',
    () async {
      final db = FakeFirebaseFirestore();
      await seedCare(db);
      final history = FeedingHistoryRepository(db);
      await history.addManual(
        userId: 'u',
        pet: max,
        grams: 50,
        food: 'Alimento',
      );
      await history.addManual(
        userId: 'u',
        pet: max,
        grams: 25,
        food: 'Alimento',
      );
      final records = await history.watchHistory('u').first;
      expect(records.every((r) => r.manual && r.isFed), isTrue);
      expect(records.fold<double>(0, (total, r) => total + r.grams), 75);
      final care = PetCareRepository(db);
      const plan = CarePlan(dailyGrams: 150, weightKg: 5, mealsPerDay: 3);
      await care.savePlan('u', 'p', plan);
      expect(plan.gramsPerMeal, 50);
      expect(plan.progress(75), .5);
      expect(plan.progress(200), 1);
      await care.saveMedical(
        'u',
        'p',
        MedicalRecord(
          id: 'visit',
          title: 'Revisión',
          kind: 'Consulta',
          date: DateTime(2026),
          notes: 'Prueba',
        ),
      );
      await PetRepository(db).deletePet('u', 'p');
      for (final collection in ['carePlan', 'medicalRecords']) {
        expect(
          (await db.collection('users/u/pets/p/$collection').get()).docs,
          isEmpty,
        );
      }
      expect(
        (await db.collection('users/u/feedingHistory').get()).docs,
        isEmpty,
      );
    },
  );
  test(
    'invitación compartida acepta y revoca sin modificar identidad ni otro espacio',
    () async {
      final db = FakeFirebaseFirestore();
      final sharing = CareSharingRepository(db);
      await sharing.invite(
        ownerId: 'u',
        ownerName: 'Ana',
        email: ' FAMILIA@example.com ',
      );
      final invite = (await db.collection('careInvitations').get()).docs.single;
      expect(invite.data()['email'], 'familia@example.com');
      await sharing.accept(invitationId: invite.id, uid: 'member');
      expect((await db.doc('users/u/caregivers/member').get()).exists, isTrue);
      expect(
        (await db.doc('users/member/careSpaces/u').get()).data()?['ownerId'],
        'u',
      );
      await sharing.revoke(
        ownerId: 'u',
        invitationId: invite.id,
        memberId: 'member',
      );
      expect((await db.doc('users/u/caregivers/member').get()).exists, isFalse);
      expect(
        (await db.doc('careInvitations/${invite.id}').get()).data()?['status'],
        'revoked',
      );
    },
  );
}
