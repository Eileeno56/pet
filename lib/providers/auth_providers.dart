import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/providers/notification_providers.dart';
import 'package:petreminder_user/repositories/auth_repository.dart';
import 'package:petreminder_user/repositories/user_repository.dart';
import 'package:petreminder_user/services/auth_service.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(userRepositoryProvider),
  ),
);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
});

// Los datos y permisos se suscriben a la identidad, no a cada edición del perfil.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(
    authStateChangesProvider.select((state) {
      final user = state.value;
      return user?.emailVerified == true ? user!.uid : null;
    }),
  );
});

final adminAccessProvider = FutureProvider<bool>((ref) async {
  ref.watch(currentUserIdProvider);
  final user = ref.read(authStateChangesProvider).value;
  if (user == null) return false;
  final token = await user.getIdTokenResult().timeout(
    const Duration(seconds: 15),
  );
  return token.claims?['admin'] == true;
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

final authTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password),
    );
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> signInWithGoogle() {
    return _run(
      ref.read(authRepositoryProvider).signInWithGoogle,
      timeout: const Duration(minutes: 3),
    );
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _run(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
    );
  }

  Future<bool> signOut() {
    return _run(() async {
      await ref
          .read(notificationServiceProvider)
          .cancelAll()
          .timeout(const Duration(seconds: 5))
          .catchError((_) {});
      await ref.read(authRepositoryProvider).signOut();
    });
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    Duration? timeout,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await operation().timeout(timeout ?? ref.read(authTimeoutProvider));
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on TimeoutException catch (_, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(
        const AuthFailure(
          'La solicitud tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
          code: 'timeout',
        ),
        stackTrace,
      );
      return false;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
