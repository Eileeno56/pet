import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';
import 'package:petreminder_user/core/auth/admin_credentials.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';
import 'package:petreminder_user/repositories/user_repository.dart';
import 'package:petreminder_user/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService, this._userRepository);

  final AuthService _authService;
  final UserRepository _userRepository;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final validation =
        InputValidators.requiredName(name) ??
        InputValidators.email(email) ??
        InputValidators.newPassword(password);
    if (validation != null) throw AuthFailure(validation);
    UserCredential? credential;

    try {
      credential = await _authService.registerWithEmail(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('No se pudo crear la cuenta.');
      }

      await user.updateDisplayName(name.trim());
      await _userRepository.createUserDocument(user: user, name: name);
    } on FirebaseAuthException catch (exception) {
      throw AuthFailure.fromFirebaseAuth(exception);
    } on AuthFailure {
      if (credential?.user != null) {
        await credential!.user!.delete().catchError((_) {});
      }
      rethrow;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signInWithEmail(
        email: AdminCredentials.normalizeEmail(email),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        if (!user.emailVerified) return;
        final token = await user
            .getIdTokenResult(true)
            .timeout(const Duration(seconds: 5));
        if (token.claims?['admin'] == true) {
          return;
        }
        await _userRepository
            .ensureAccountIsActive(user)
            .timeout(const Duration(seconds: 5));
        await _userRepository
            .updateLastActivity(user)
            .timeout(const Duration(seconds: 5));
      }
    } on TimeoutException {
      unawaited(_authService.signOut().catchError((_) {}));
      throw const AuthFailure(
        'La solicitud tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
        code: 'timeout',
      );
    } on FirebaseAuthException catch (exception) {
      throw AuthFailure.fromFirebaseAuth(exception);
    } on AuthFailure {
      await _authService.signOut().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('No se pudo iniciar sesión con Google.');
      }
      await _userRepository.ensureGoogleUserDocument(user);
      await _userRepository.ensureAccountIsActive(user);
    } on FirebaseAuthException catch (exception) {
      throw AuthFailure.fromFirebaseAuth(exception);
    } on AuthFailure catch (failure) {
      if (failure.code != 'canceled') {
        await _authService.signOut();
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
    } on FirebaseAuthException catch (exception) {
      throw AuthFailure.fromFirebaseAuth(exception);
    }
  }

  Future<void> signOut() => _authService.signOut();
}
