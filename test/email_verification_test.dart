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
    'deep links remain blocked when email confirmation is still pending',
    (tester) async {
      final service = MockVerification();
      when(() => service.refresh()).thenAnswer((_) async => false);
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
      await tester.ensureVisible(find.text('Ya confirmé mi correo'));
      await tester.tap(find.text('Ya confirmé mi correo'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Tu correo aún no está confirmado.'),
        findsOneWidget,
      );
      expect(router.routeInformationProvider.value.uri.path, '/verify-email');
      verify(() => service.refresh()).called(1);
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
      await tester.tap(find.text('Enviar enlace de confirmación'));
      await tester.pumpAndSettle();
      verify(() => service.send()).called(1);
      expect(find.textContaining('Enlace enviado.'), findsOneWidget);
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
      when(() => user.emailVerified).thenReturn(true);
      expect(await EmailVerificationService(auth).refresh(), isTrue);
      verifyInOrder([() => user.getIdToken(true), () => user.reload()]);
    },
  );
  test(
    'verification message uses the current Firebase user and Spanish language',
    () async {
      final auth = MockAuth();
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.emailVerified).thenReturn(false);
      when(() => auth.setLanguageCode('es')).thenAnswer((_) async {});
      when(() => user.sendEmailVerification()).thenAnswer((_) async {});
      await EmailVerificationService(auth).send();
      verifyInOrder([
        () => auth.setLanguageCode('es'),
        () => user.sendEmailVerification(),
      ]);
    },
  );
  test('verified users do not send additional messages', () async {
    final auth = MockAuth();
    final user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.emailVerified).thenReturn(true);
    await EmailVerificationService(auth).send();
    verifyNever(() => user.sendEmailVerification());
  });
}
