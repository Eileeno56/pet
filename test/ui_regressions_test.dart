import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:petreminder_admin/providers/admin_providers.dart' as admin;
import 'package:petreminder_admin/providers/firebase_providers.dart'
    as admin_firebase;
import 'package:petreminder_user/app.dart';
import 'package:petreminder_user/providers/sync_status_provider.dart';
import 'package:petreminder_user/features/pets/presentation/pets_screen.dart';
import 'package:petreminder_user/features/profile/presentation/profile_screen.dart';
import 'package:petreminder_user/models/app_user.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/feeding_history_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/providers/notification_providers.dart';
import 'package:petreminder_user/providers/pet_providers.dart';
import 'package:petreminder_user/providers/profile_providers.dart';
import 'package:petreminder_user/providers/router_provider.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'u';
  @override
  String? get displayName => 'María Pérez';
  @override
  String? get email => 'maria@example.com';
}

void main() {
  testWidgets(
    'editar el nombre no reinicia la sesión ni saca al usuario del perfil',
    (tester) async {
      final changes = StreamController<User?>();
      final db = FakeFirebaseFirestore();
      await db.doc('users/u').set({
        'uid': 'u',
        'name': 'María Pérez',
        'email': 'maria@example.com',
      });
      var permissionChecks = 0;
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          currentDateProvider.overrideWith((ref) => Stream.value('2026-10-26')),
          authStateChangesProvider.overrideWith((ref) => changes.stream),
          adminAccessProvider.overrideWith((ref) async {
            final uid = ref.watch(currentUserIdProvider);
            if (uid != null) {
              permissionChecks++;
            }
            return false;
          }),
          petsProvider.overrideWith((ref) => Stream.value([])),
          profilePhotoPathProvider.overrideWith((ref) async => null),
          notificationSyncProvider.overrideWith((ref) async {}),
          ensureTodayForAllPetsProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await changes.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PetReminderApp(),
        ),
      );
      changes.add(FakeUser());
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/profile');
      await tester.pumpAndSettle();
      final before = permissionChecks;
      await db.doc('users/u').update({'name': 'María Actualizada'});
      changes.add(
        FakeUser(),
      ); // userChanges también se emite al editar displayName.
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      expect(find.text('María Actualizada'), findsOneWidget);
      expect(permissionChecks, before);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'solo hay una entrada para agregar mascota y abre el formulario',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const PetsScreen()),
          GoRoute(
            path: '/pets/new',
            builder: (_, _) =>
                const Scaffold(body: Text('Formulario de mascota')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            petsProvider.overrideWith((ref) => Stream.value([])),
            ensureTodayForAllPetsProvider.overrideWith((ref) async {}),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agregar mascota'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      await tester.tap(find.text('Agregar mascota'));
      await tester.pumpAndSettle();
      expect(find.text('Formulario de mascota'), findsOneWidget);
    },
  );

  testWidgets(
    'perfil usa nombre de Auth mientras falta el documento de Firestore',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(FakeUser()),
            ),
            appUserProvider.overrideWith((ref) => Stream.value(null)),
            profilePhotoPathProvider.overrideWith((ref) async => null),
            feedingHistoryProvider.overrideWith((ref) => const AsyncData([])),
            petsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('María Pérez'), findsOneWidget);
      expect(find.text('maria@example.com'), findsOneWidget);
      expect(find.text('Usuario'), findsNothing);
    },
  );

  testWidgets('sesión admin abre módulo integrado, navega y cierra sesión', (
    tester,
  ) async {
    final changes = StreamController<User?>();
    final auth = MockAuth();
    when(() => auth.signOut()).thenAnswer((_) async {
      changes.add(null);
    });
    final profileChanges = StreamController<AppUser?>();
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => changes.stream),
        adminAccessProvider.overrideWith((ref) async => true),
        appUserProvider.overrideWith((ref) => profileChanges.stream),
        admin_firebase.firebaseAuthProvider.overrideWithValue(auth),
        admin.usersProvider.overrideWith((ref) => Stream.value([])),
        admin.allPetsProvider.overrideWith((ref) => Stream.value([])),
        admin.allSchedulesProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await changes.close();
      await profileChanges.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PetReminderApp(),
      ),
    );
    changes.add(FakeUser());
    await tester.pumpAndSettle();
    expect(find.text('PetReminder Admin'), findsOneWidget);
    final router = container.read(routerProvider);
    router.go('/admin/users');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/users');
    profileChanges.add(null);
    await tester.pumpAndSettle();
    expect(identical(router, container.read(routerProvider)), true);
    expect(router.routeInformationProvider.value.uri.path, '/admin/users');
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido'), findsOneWidget);
    verify(() => auth.signOut()).called(1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('una cuenta normal no puede abrir las rutas admin', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(FakeUser()),
        ),
        adminAccessProvider.overrideWith((ref) async => false),
        appUserProvider.overrideWith((ref) => Stream.value(null)),
        petsProvider.overrideWith((ref) => Stream.value([])),
        notificationSyncProvider.overrideWith((ref) async {}),
        syncStatusProvider.overrideWith((ref) => Stream.value(null)),
        ensureTodayForAllPetsProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PetReminderApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    router.go('/admin/users');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('PetReminder Admin'), findsNothing);
    expect(find.text('Agregar mascota'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
