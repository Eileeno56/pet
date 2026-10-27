import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petreminder_user/features/auth/presentation/verify_email_screen.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/router_provider.dart';
import 'package:petreminder_user/services/email_verification_service.dart';

class UnverifiedUser extends Fake implements User {
  @override
  String get uid => 'unverified';
  @override
  String? get email => 'pending@example.com';
  @override
  bool get emailVerified => false;
}

class MockVerification extends Mock implements EmailVerificationService {}

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFunctions extends Mock implements FirebaseFunctions {}

void main() {
  test('unverified session cannot activate data providers', () async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(UnverifiedUser()),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(currentUserIdProvider, (_, _) {}, fireImmediately: true);
    await pumpEventQueue();
    expect(container.read(currentUserIdProvider), isNull);
  });
  testWidgets(
    'deep links require verification and short codes never call server',
    (tester) async {
      final service = MockVerification();
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(UnverifiedUser()),
          ),
          adminAccessProvider.overrideWith((ref) async => false),
          emailVerificationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      for (final path in [
        '/history',
        '/profile',
        '/family',
        '/admin/dashboard',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/verify-email');
      }
      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.ensureVisible(find.text('Confirmar correo'));
      await tester.tap(find.text('Confirmar correo'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe los 5 dígitos.'), findsOneWidget);
      verifyNever(() => service.verify(any()));
    },
  );
  testWidgets(
    'sending is explicit and prevents repeated requests during cooldown',
    (tester) async {
      final service = MockVerification();
      when(() => service.send()).thenAnswer((_) async {});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(UnverifiedUser()),
            ),
            emailVerificationServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(home: VerifyEmailScreen()),
        ),
      );
      await tester.pumpAndSettle();
      verifyNever(() => service.send());
      await tester.tap(find.text('Enviar código al correo'));
      await tester.pumpAndSettle();
      verify(() => service.send()).called(1);
      expect(find.textContaining('Código enviado.'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'refresh obtains fresh server claims before allowing userChanges',
    () async {
      final auth = MockAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(
        () => user.getIdToken(true),
      ).thenAnswer((_) async => 'fresh-test-token');
      when(() => user.reload()).thenAnswer((_) async {});
      await EmailVerificationService(auth, MockFunctions()).refresh();
      verifyInOrder([() => user.getIdToken(true), () => user.reload()]);
    },
  );
}
