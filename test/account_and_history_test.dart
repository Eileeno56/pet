import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petreminder_user/core/errors/feeding_history_failure.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/feeding_history_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/providers/profile_providers.dart';
import 'package:petreminder_user/repositories/feeding_history_repository.dart';
import 'package:petreminder_user/repositories/feeding_schedule_repository.dart';
import 'package:petreminder_user/repositories/pet_repository.dart';
import 'package:petreminder_user/repositories/user_repository.dart';

class TestUser extends Fake implements User {
  @override
  bool get emailVerified => true;
  TestUser(
    this.uid, {
    this.displayName = 'María',
    this.email = 'maria@example.com',
  });
  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? email;
  @override
  String? get photoURL => null;
}

Pet pet(String id) => Pet(
  id: id,
  name: 'Max',
  species: 'Perro',
  breed: '',
  age: 3,
  description: '',
  photoUrl: null,
  createdAt: DateTime(2026),
);

Future<void> seed(FakeFirebaseFirestore db) async {
  await db.doc('users/u/pets/p').set({
    'name': 'Max',
    'species': 'Perro',
    'createdAt': DateTime(2026),
  });
  await db.doc('users/u/pets/p/feedingSchedules/s').set({
    'id': 's',
    'time': '08:00',
    'active': true,
    'createdAt': DateTime(2026),
  });
}

void main() {
  test('perfil sigue inicio, cambio de cuenta y cierre de sesión', () async {
    final db = FakeFirebaseFirestore();
    await db.doc('users/a').set({'uid': 'a', 'name': 'Ana'});
    await db.doc('users/b').set({'uid': 'b', 'name': 'Beatriz'});
    final auth = StreamController<User?>();
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        authStateChangesProvider.overrideWith((ref) => auth.stream),
      ],
    );
    final sub = container.listen(appUserProvider, (_, _) {});
    addTearDown(() async {
      sub.close();
      container.dispose();
      await auth.close();
    });
    auth.add(null);
    await pumpEventQueue();
    expect(await container.read(appUserProvider.future), isNull);
    auth.add(TestUser('a'));
    await pumpEventQueue();
    expect((await container.read(appUserProvider.future))?.name, 'Ana');
    auth.add(TestUser('b'));
    await pumpEventQueue();
    expect((await container.read(appUserProvider.future))?.name, 'Beatriz');
    auth.add(null);
    await pumpEventQueue();
    expect(await container.read(appUserProvider.future), isNull);
  });

  test(
    'repara perfil ausente o nombre vacío sin reemplazar nombre guardado',
    () async {
      final db = FakeFirebaseFirestore();
      final repository = UserRepository(db);
      final user = TestUser('u');
      await repository.updateLastActivity(user);
      expect((await db.doc('users/u').get()).data()?['name'], 'María');
      await db.doc('users/u').update({'name': 'Nombre elegido'});
      await repository.updateLastActivity(user);
      expect((await db.doc('users/u').get()).data()?['name'], 'Nombre elegido');
      await db.doc('users/u').update({'name': ''});
      await repository.updateLastActivity(user);
      expect((await db.doc('users/u').get()).data()?['name'], 'María');
    },
  );

  test(
    'elimina todos los registros de un horario sin afectar otro horario o mascota',
    () async {
      final db = FakeFirebaseFirestore();
      await seed(db);
      for (var n = 0; n < 455; n++) {
        await db.doc('users/u/feedingHistory/$n').set({
          'petId': 'p',
          'scheduleId': 's',
        });
      }
      await db.doc('users/u/feedingHistory/other-schedule').set({
        'petId': 'p',
        'scheduleId': 'other',
      });
      await db.doc('users/u/feedingHistory/other-pet').set({
        'petId': 'other',
        'scheduleId': 's',
      });
      await FeedingScheduleRepository(db).deleteSchedule('u', 'p', 's');
      expect(
        (await db.doc('users/u/pets/p/feedingSchedules/s').get()).exists,
        false,
      );
      expect(
        (await db.collection('users/u/feedingHistory').get()).docs
            .map((d) => d.id)
            .toSet(),
        {'other-schedule', 'other-pet'},
      );
    },
  );

  test(
    'borrar mascota limpia horarios e historial y conserva otras mascotas',
    () async {
      final db = FakeFirebaseFirestore();
      await seed(db);
      await db.doc('users/u/feedingHistory/fed').set({
        'petId': 'p',
        'scheduleId': 's',
        'status': 'fed',
      });
      await db.doc('users/u/feedingHistory/pending').set({
        'petId': 'p',
        'scheduleId': 's',
        'status': 'pending',
      });
      await db.doc('users/u/feedingHistory/keep').set({
        'petId': 'other',
        'scheduleId': 's',
      });
      await PetRepository(db).deletePet('u', 'p');
      expect((await db.doc('users/u/pets/p').get()).exists, false);
      expect(
        (await db.collection('users/u/pets/p/feedingSchedules').get()).docs,
        isEmpty,
      );
      expect(
        (await db.collection('users/u/feedingHistory').get()).docs.single.id,
        'keep',
      );
    },
  );

  test('no recrea comidas para una mascota o un horario eliminados', () async {
    final db = FakeFirebaseFirestore();
    await seed(db);
    await db.doc('users/u/pets/p').delete();
    final history = FeedingHistoryRepository(db);
    await history.ensureTodayForPet('u', pet('p'));
    expect((await db.collection('users/u/feedingHistory').get()).docs, isEmpty);
    await expectLater(
      history.markAsFed(
        userId: 'u',
        pet: pet('p'),
        scheduleId: 's',
        scheduledTime: '08:00',
      ),
      throwsA(isA<FeedingHistoryFailure>()),
    );
    await seed(db);
    await db.doc('users/u/pets/p/feedingSchedules/s').delete();
    await expectLater(
      history.markAsFed(
        userId: 'u',
        pet: pet('p'),
        scheduleId: 's',
        scheduledTime: '08:00',
      ),
      throwsA(isA<FeedingHistoryFailure>()),
    );
  });

  test(
    'historial y estadísticas ocultan huérfanos antiguos y reaccionan al borrado',
    () async {
      final db = FakeFirebaseFirestore();
      await seed(db);
      final history = FeedingHistoryRepository(db);
      await history.ensureTodayForPet('u', pet('p'));
      await db.doc('users/u/feedingHistory/orphan-pet').set({
        'petId': 'deleted',
        'scheduleId': 's',
      });
      await db.doc('users/u/feedingHistory/orphan-schedule').set({
        'petId': 'p',
        'scheduleId': 'deleted',
      });
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(TestUser('u')),
          ),
        ],
      );
      final sub = container.listen(feedingHistoryProvider, (_, _) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });
      await pumpEventQueue(times: 40);
      expect(container.read(feedingHistoryProvider).value?.length, 1);
      await db.doc('users/u/pets/p/feedingSchedules/s').delete();
      await pumpEventQueue(times: 40);
      expect(container.read(feedingHistoryProvider).value, isEmpty);
    },
  );
}
