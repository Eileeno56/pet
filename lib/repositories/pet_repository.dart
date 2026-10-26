import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petreminder_user/core/errors/pet_failure.dart';
import 'package:petreminder_user/core/firestore/delete_query.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/core/validators/input_validators.dart';

class PetRepository {
  PetRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Pet>> watchPets(String userId) {
    return _pets(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Pet.fromDocument).toList());
  }

  Future<String> createPet(String userId, PetInput input) async {
    _validate(input);
    final reference = _pets(userId).doc();

    try {
      await reference.set({
        ...input.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return reference.id;
    } on FirebaseException catch (exception) {
      throw PetFailure.fromFirebase(exception);
    }
  }

  Future<void> updatePet(String userId, String petId, PetInput input) async {
    _validate(input);
    try {
      await _pets(userId).doc(petId).update(input.toFirestore());
    } on FirebaseException catch (exception) {
      throw PetFailure.fromFirebase(exception);
    }
  }

  Future<void> deletePet(String userId, String petId) async {
    try {
      final petReference = _pets(userId).doc(petId);
      // Primero se retira la mascota para impedir nuevos registros concurrentes.
      await petReference.delete();
      for (final name in ['feedingSchedules', 'carePlan', 'medicalRecords']) {
        await deleteQuery(_firestore, petReference.collection(name));
      }
      await deleteQuery(
        _firestore,
        _firestore
            .collection('users')
            .doc(userId)
            .collection('feedingHistory')
            .where('petId', isEqualTo: petId),
      );
    } on FirebaseException catch (exception) {
      throw PetFailure.fromFirebase(exception);
    }
  }

  void _validate(PetInput input) {
    final error =
        InputValidators.petName(input.name) ??
        InputValidators.petAge(
          '${input.age}',
          species: input.species,
          months: input.ageMonths,
        ) ??
        InputValidators.petMonths('${input.ageMonths}') ??
        InputValidators.petDescription(input.description);
    if (error != null) throw PetFailure(error);
  }

  CollectionReference<Map<String, dynamic>> _pets(String userId) =>
      _firestore.collection('users').doc(userId).collection('pets');
}
