import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';

class EmailVerificationService {
  EmailVerificationService(this.auth, this.functions);
  final FirebaseAuth auth;
  final FirebaseFunctions functions;

  Future<void> send() => _call('sendEmailCode', const {});

  Future<void> verify(String code) async {
    await _call('verifyEmailCode', {'code': code});
    await refresh();
  }

  Future<void> refresh() async {
    final user = auth.currentUser;
    if (user == null) throw const AuthFailure('Inicia sesión otra vez.');
    // Refresh claims before userChanges lets the router open data subscriptions.
    await user.getIdToken(true).timeout(const Duration(seconds: 15));
    await user.reload().timeout(const Duration(seconds: 15));
  }

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          )
          .call<Map<String, dynamic>>(data);
    } on FirebaseFunctionsException catch (error) {
      final message = switch (error.code) {
        'unauthenticated' => 'Tu sesión venció. Sal e inicia sesión otra vez.',
        'resource-exhausted' =>
          'Se alcanzó el límite de intentos o envíos. Espera antes de reintentar.',
        'invalid-argument' =>
          'El código no es correcto. Escribe los 5 dígitos recibidos.',
        'failed-precondition' =>
          'El código venció o ya no está disponible. Solicita otro.',
        'permission-denied' => 'Esta cuenta no puede confirmar el correo.',
        _ =>
          'No fue posible completar la confirmación. Revisa tu conexión e inténtalo de nuevo.',
      };
      throw AuthFailure(message, code: error.code);
    }
  }
}
