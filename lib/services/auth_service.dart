import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';

class AuthService {
  AuthService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    var expired = false;
    final pending = _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Firebase no cancela solicitudes nativas: descartar también un éxito tardío.
    unawaited(
      pending.then<void>((_) async {
        if (expired) await _firebaseAuth.signOut();
      }, onError: (Object _, StackTrace _) {}),
    );
    try {
      return await pending.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      expired = true;
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthFailure(
          'Google no devolvió una credencial válida.',
          code: 'missing-google-id-token',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (exception) {
      throw AuthFailure.fromGoogleSignIn(exception);
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } on GoogleSignInException {
      // Firebase is already signed out, which is the app's source of truth.
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }
}
