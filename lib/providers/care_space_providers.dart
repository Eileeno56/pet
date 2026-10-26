import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';

/// Cambia el espacio de mascotas sin cambiar la identidad autenticada.
final careSpaceSelectionProvider =
    NotifierProvider<CareSpaceSelection, String?>(CareSpaceSelection.new);

class CareSpaceSelection extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(currentUserIdProvider);
    return null;
  }

  void select(String? ownerId) {
    state = ownerId;
  }
}

final careOwnerIdProvider = Provider<String?>(
  (ref) =>
      ref.watch(careSpaceSelectionProvider) ?? ref.watch(currentUserIdProvider),
);

final careSpacesProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) return Stream.value([]);
      return ref
          .watch(firestoreProvider)
          .collection('users/$uid/careSpaces')
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
    });

final careInvitationsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final user = ref.watch(authStateChangesProvider).value;
      if (user == null || !user.emailVerified || user.email == null) {
        return Stream.value([]);
      }
      return ref
          .watch(firestoreProvider)
          .collection('careInvitations')
          .where('email', isEqualTo: user.email!.toLowerCase())
          .snapshots()
          .map(
            (s) => s.docs
                .where((d) => d.data()['status'] == 'pending')
                .map((d) => {...d.data(), 'id': d.id})
                .toList(),
          );
    });

final outgoingCareInvitationsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) return Stream.value([]);
      return ref
          .watch(firestoreProvider)
          .collection('careInvitations')
          .where('ownerId', isEqualTo: uid)
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
    });

final caregiversProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) return Stream.value([]);
      return ref
          .watch(firestoreProvider)
          .collection('users/$uid/caregivers')
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
    });

/// Permite detectar revocación sin intentar leer información que ya no es accesible.
final selectedMembershipProvider = StreamProvider.autoDispose<bool>((ref) {
  final owner = ref.watch(careOwnerIdProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (owner == null || uid == null || owner == uid) return Stream.value(true);
  return ref
      .watch(firestoreProvider)
      .doc('users/$owner/caregivers/$uid')
      .snapshots()
      .map((d) => d.exists);
});

final careSharingRepositoryProvider = Provider(
  (ref) => CareSharingRepository(ref.watch(firestoreProvider)),
);

class CareSharingRepository {
  CareSharingRepository(this.db);
  final FirebaseFirestore db;

  Future<void> invite({
    required String ownerId,
    required String ownerName,
    required String email,
  }) async {
    // Invitación dentro de la app, asociada al correo verificado del destinatario.
    final cleanEmail = email.trim().toLowerCase();
    final existing = await db
        .collection('careInvitations')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    if (existing.docs.any(
      (d) => d.data()['email'] == cleanEmail && d.data()['status'] == 'pending',
    )) {
      throw StateError('Ya existe una invitación pendiente para ese correo.');
    }
    await db
        .collection('careInvitations')
        .add({
          'ownerId': ownerId,
          'ownerName': ownerName,
          'email': cleanEmail,
          'status': 'pending',
          'acceptedBy': null,
          'createdAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> accept({
    required String invitationId,
    required String uid,
  }) async {
    final invite = db.doc('careInvitations/$invitationId');
    await db
        .runTransaction((tx) async {
          final snapshot = await tx.get(invite);
          final data = snapshot.data();
          if (data == null || data['status'] != 'pending') {
            throw StateError('La invitación ya no está disponible.');
          }
          final owner = data['ownerId'] as String;
          tx.update(invite, {'status': 'accepted', 'acceptedBy': uid});
          tx.set(db.doc('users/$owner/caregivers/$uid'), {
            'uid': uid,
            'email': data['email'],
            'invitationId': invitationId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tx.set(db.doc('users/$uid/careSpaces/$owner'), {
            'ownerId': owner,
            'ownerName': data['ownerName'],
            'invitationId': invitationId,
          });
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> revoke({
    required String ownerId,
    required String invitationId,
    String? memberId,
  }) async {
    final batch = db.batch();
    batch.update(db.doc('careInvitations/$invitationId'), {
      'status': 'revoked',
    });
    if (memberId != null) {
      batch.delete(db.doc('users/$ownerId/caregivers/$memberId'));
    }
    await batch.commit().timeout(const Duration(seconds: 15));
  }
}
