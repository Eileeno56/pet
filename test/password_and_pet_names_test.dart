import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petreminder_user/core/errors/pet_failure.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';
import 'package:petreminder_user/features/auth/presentation/widgets/password_strength_indicator.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/repositories/pet_repository.dart';

PetInput input(String name) =>
    PetInput(name: name, species: 'Gato', breed: '', age: 1, description: '');

void main() {
  test('ocho caracteres con composición y rechazo de patrones comunes', () {
    for (final password in [
      '',
      'Ab3!xyz',
      'abcdefgh',
      'ABCDEFGH',
      'Abcdefgh',
      'Abcdefg1',
      'Password1!',
      'Qwerty123!',
      'Aa1!Aa1!',
    ]) {
      expect(
        InputValidators.newPassword(password),
        isNotNull,
        reason: password,
      );
      expect(InputValidators.passwordStrength(password), 0);
    }
    expect(InputValidators.newPassword('Luz7!mar'), isNull);
    expect(InputValidators.newPassword('abc'), 'Usa al menos 8 caracteres.');
    expect(InputValidators.passwordStrength('Luz7!mar'), 1);
    expect(InputValidators.passwordStrength('Luna!Bosque27'), 2);
    expect(InputValidators.newPassword('Luna!Bosque27' * 11), isNotNull);
    expect(InputValidators.password('123456'), isNull);
  });

  testWidgets(
    'el indicador muestra texto accesible y círculos de tres colores',
    (tester) async {
      for (final entry in [
        ('abc', 'Poco seguro', Colors.red.shade700),
        ('Luz7!mar', 'Seguro', Colors.amber.shade700),
        ('Luna!Bosque27', 'Muy seguro', Colors.green.shade700),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PasswordStrengthIndicator(password: entry.$1)),
          ),
        );
        expect(find.text(entry.$2), findsOneWidget);
        final icon = tester.widget<Icon>(find.byIcon(Icons.circle));
        expect(icon.color, entry.$3);
        expect(
          find.bySemanticsLabel('Seguridad de la contraseña: ${entry.$2}'),
          findsOneWidget,
        );
      }
    },
  );

  test(
    'crear y renombrar bloquea duplicados por espacio y libera al borrar',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = PetRepository(db);
      final max = await repo.createPet('u', input('Max'));
      await expectLater(
        repo.createPet('u', input('  MAX  ')),
        throwsA(isA<PetFailure>()),
      );
      await repo.updatePet('u', max, input('MAX'));
      final luna = await repo.createPet('u', input('Luna'));
      await expectLater(
        repo.updatePet('u', luna, input('max')),
        throwsA(isA<PetFailure>()),
      );
      await repo.createPet('other', input('Max'));
      await repo.updatePet('u', max, input('Toby'));
      await repo.createPet('u', input('Max'));
      await repo.deletePet('u', luna);
      await repo.createPet('u', input('Luna'));
      expect((await db.doc('users/u/petNames/toby').get()).data()?['petIds'], [
        max,
      ]);
    },
  );

  test(
    'duplicados anteriores se conservan y solo pueden liberar su reserva',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = PetRepository(db);
      await db.doc('users/u/petNames/max').set({
        'petIds': ['a', 'b'],
      });
      for (final id in ['a', 'b']) {
        await db.doc('users/u/pets/$id').set({
          ...input('Max').toFirestore(),
          'nameKey': 'max',
          'createdAt': DateTime(2026),
        });
      }
      await expectLater(
        repo.createPet('u', input('Max')),
        throwsA(isA<PetFailure>()),
      );
      await expectLater(
        repo.updatePet('u', 'a', input('MAX')),
        throwsA(isA<PetFailure>()),
      );
      await repo.updatePet('u', 'a', input('Toby'));
      expect((await db.doc('users/u/petNames/max').get()).data()?['petIds'], [
        'b',
      ]);
      expect((await db.doc('users/u/pets/b').get()).data()?['name'], 'Max');
      await repo.deletePet('u', 'b');
      expect((await db.doc('users/u/petNames/max').get()).exists, isFalse);
    },
  );
}
