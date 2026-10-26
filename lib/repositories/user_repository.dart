import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petreminder_user/core/errors/auth_failure.dart';
import 'package:petreminder_user/models/app_user.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<AppUser?> watchUser(String userId) {
    return _users.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : AppUser.fromFirestore(data);
    });
  }

  Future<void> createUserDocument({
    required User user,
    required String name,
  }) async {
    try {
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'accountStatus': AppUser.activeStatus,
      });
    } on FirebaseException catch (exception) {
      throw _firestoreFailure(exception);
    }
  }

  Future<void> ensureGoogleUserDocument(User user) async {
    final reference = _users.doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        final data = snapshot.data();
        if (data?['accountStatus'] == AppUser.disabledStatus) {
          throw const AuthFailure(
            'Esta cuenta se encuentra deshabilitada.',
            code: 'user-disabled',
          );
        }
        final name = _nameFor(user);
        if (snapshot.exists) {
          transaction.update(reference, {
            if ((data?['name'] as String? ?? '').trim().isEmpty) 'name': name,
            'lastActivity': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(reference, {
            'uid': user.uid,
            'name': name,
            'email': user.email ?? '',
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'lastActivity': FieldValue.serverTimestamp(),
            'accountStatus': AppUser.activeStatus,
          });
        }
      });
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (exception) {
      throw _firestoreFailure(exception);
    }
  }

  Future<void> updateLastActivity(User user) async {
    await ensureGoogleUserDocument(user);
  }

  String _nameFor(User user) {
    final displayName = user.displayName?.trim() ?? '';
    final emailName = user.email?.split('@').first.trim() ?? '';
    final candidate = (displayName.length >= 2 ? displayName : emailName)
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿĀ-ž ]'), '')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
    final name = candidate.length >= 2
        ? candidate.substring(0, candidate.length.clamp(0, 60)).trim()
        : 'Mi perfil';
    return InputValidators.requiredName(name) == null ? name : 'Mi perfil';
  }

  Future<void> ensureAccountIsActive(User user) async {
    try {
      final snapshot = await _users.doc(user.uid).get();
      final status = snapshot.data()?['accountStatus'] as String?;
      if (status == AppUser.disabledStatus) {
        throw const AuthFailure(
          'Esta cuenta se encuentra deshabilitada.',
          code: 'user-disabled',
        );
      }
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (exception) {
      throw _firestoreFailure(exception);
    }
  }

  Future<void> updateName(String userId, String name) async {
    final error = InputValidators.requiredName(name);
    if (error != null) throw AuthFailure(error);
    try {
      await _users
          .doc(userId)
          .update({
            'name': name.trim(),
            'lastActivity': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));
    } on FirebaseException catch (exception) {
      throw _firestoreFailure(exception);
    }
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  AuthFailure _firestoreFailure(FirebaseException exception) {
    if (exception.code == 'unavailable' ||
        exception.code == 'network-request-failed') {
      return const AuthFailure(
        'No se pudo conectar. Revisa tu conexión a internet.',
        code: 'network-request-failed',
      );
    }

    return AuthFailure(
      'No se pudo guardar la información de la cuenta.',
      code: exception.code,
    );
  }
}
