import 'package:firebase_auth/firebase_auth.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';

class EmailVerificationService {
  EmailVerificationService(this.auth);
  final FirebaseAuth auth;

  Future<void> send() async {
    final user = auth.currentUser;
    if (user == null) throw const AuthFailure('Inicia sesión otra vez.');
    if (user.emailVerified) return;
    try {
      await auth.setLanguageCode('es');
      await user.sendEmailVerification().timeout(const Duration(seconds: 20));
    } on FirebaseAuthException catch (error) {
      throw AuthFailure.fromFirebaseAuth(error);
    }
  }

  Future<bool> refresh() async {
    final user = auth.currentUser;
    if (user == null) throw const AuthFailure('Inicia sesión otra vez.');
    // Refresh claims before userChanges lets the router open data subscriptions.
    await user.getIdToken(true).timeout(const Duration(seconds: 15));
    await user.reload().timeout(const Duration(seconds: 15));
    return auth.currentUser?.emailVerified == true;
  }
}
