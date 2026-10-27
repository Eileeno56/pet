import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  factory AuthFailure.fromFirebaseAuth(FirebaseAuthException exception) {
    final message = switch (exception.code) {
      'invalid-email' => 'El correo electrónico no es válido.',
      'wrong-password' || 'invalid-credential' || 'user-not-found' =>
        'No fue posible iniciar sesión. Revisa tus datos e inténtalo de nuevo.',
      'email-already-in-use' =>
        'Ya existe una cuenta registrada con ese correo.',
      'weak-password' || 'password-does-not-meet-requirements' =>
        'La contraseña no cumple los requisitos. Usa una frase larga y única.',
      'user-disabled' => 'Esta cuenta se encuentra deshabilitada.',
      'operation-not-allowed' => 'Este método de acceso no está habilitado.',
      'too-many-requests' =>
        'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
      'network-request-failed' =>
        'No se pudo conectar. Revisa tu conexión a internet.',
      'account-exists-with-different-credential' =>
        'Ese correo ya está asociado a otro método de acceso.',
      _ => 'No se pudo completar la autenticación. Inténtalo de nuevo.',
    };

    return AuthFailure(message, code: exception.code);
  }

  factory AuthFailure.fromGoogleSignIn(GoogleSignInException exception) {
    final message = switch (exception.code) {
      GoogleSignInExceptionCode.canceled =>
        'Se canceló el inicio de sesión con Google.',
      GoogleSignInExceptionCode.interrupted =>
        'El inicio de sesión con Google fue interrumpido.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google Sign-In no está configurado correctamente.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'No se pudo abrir el inicio de sesión con Google.',
      _ => 'No se pudo iniciar sesión con Google.',
    };

    return AuthFailure(message, code: exception.code.name);
  }

  @override
  String toString() => message;
}
