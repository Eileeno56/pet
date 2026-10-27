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
      final key = InputValidators.petNameKey(input.name);
      final nameReference = _names(userId).doc(key);
      await _firestore.runTransaction((transaction) async {
        final reservation = await transaction.get(nameReference);
        if (reservation.exists) {
          throw const PetFailure(
            'Ya existe una mascota con ese nombre en este espacio.',
          );
        }
        transaction.set(nameReference, {
          'petIds': [reference.id],
        });
        transaction.set(reference, {
          ...input.toFirestore(),
          'nameKey': key,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return reference.id;
    } on FirebaseException catch (exception) {
      throw PetFailure.fromFirebase(exception);
    }
  }

  Future<void> updatePet(String userId, String petId, PetInput input) async {
    _validate(input);
    try {
      final reference = _pets(userId).doc(petId);
      final key = InputValidators.petNameKey(input.name);
      await _firestore.runTransaction((transaction) async {
        final pet = await transaction.get(reference);
        if (!pet.exists) {
          throw const PetFailure('La mascota ya no está disponible.');
        }
        final oldKey = InputValidators.petNameKey(
          pet.data()!['name'] as String,
        );
        final oldReference = _names(userId).doc(oldKey);
        final oldReservation = await transaction.get(oldReference);
        final targetReference = _names(userId).doc(key);
        final target = key == oldKey
            ? oldReservation
            : await transaction.get(targetReference);
        final ids = List<String>.from(target.data()?['petIds'] ?? []);
        if (target.exists &&
            (key != oldKey || ids.length != 1 || ids.single != petId)) {
          throw const PetFailure(
            'Ya existe una mascota con ese nombre en este espacio. Elige otro nombre.',
          );
        }
        if (key != oldKey) {
          _release(transaction, oldReference, oldReservation.data(), petId);
        }
        if (!target.exists) {
          transaction.set(targetReference, {
            'petIds': [petId],
          });
        }
        transaction.update(reference, {...input.toFirestore(), 'nameKey': key});
      });
    } on FirebaseException catch (exception) {
      throw PetFailure.fromFirebase(exception);
    }
  }

  Future<void> deletePet(String userId, String petId) async {
    try {
      final petReference = _pets(userId).doc(petId);
      // Primero se retira la mascota para impedir nuevos registros concurrentes.
      await _firestore.runTransaction((transaction) async {
        final pet = await transaction.get(petReference);
        if (pet.exists) {
          final key = InputValidators.petNameKey(pet.data()!['name'] as String);
          final nameReference = _names(userId).doc(key);
          final reservation = await transaction.get(nameReference);
          _release(transaction, nameReference, reservation.data(), petId);
          transaction.delete(petReference);
        }
      });
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

  CollectionReference<Map<String, dynamic>> _names(String userId) =>
      _firestore.collection('users').doc(userId).collection('petNames');

  void _release(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic>? data,
    String petId,
  ) {
    if (data == null) return;
    final remaining = List<String>.from(data['petIds'] as List)..remove(petId);
    if (remaining.isEmpty) {
      transaction.delete(reference);
    } else {
      transaction.update(reference, {'petIds': remaining});
    }
  }
}
