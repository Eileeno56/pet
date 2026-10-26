import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petreminder_user/core/errors/feeding_history_failure.dart';
import 'package:petreminder_user/models/feeding_record.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/models/feeding_schedule.dart';

class FeedingHistoryRepository {
  FeedingHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<FeedingRecord>> watchHistory(String userId) {
    return _history(userId).snapshots().map((snapshot) {
      final records = snapshot.docs.map(FeedingRecord.fromDocument).toList();
      records.sort((a, b) {
        final dateComparison = b.dateKey.compareTo(a.dateKey);
        return dateComparison != 0
            ? dateComparison
            : b.scheduledTime.compareTo(a.scheduledTime);
      });
      return records;
    });
  }

  Future<void> ensureTodayForPet(String userId, Pet pet) async {
    try {
      final schedules = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(pet.id)
          .collection('feedingSchedules')
          .where('active', isEqualTo: true)
          .get();
      if (schedules.docs.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final dateKey = FeedingRecord.dateKeyFor(now);
      for (final schedule in schedules.docs) {
        if (!FeedingSchedule.fromDocument(schedule).occursOn(now)) continue;
        final id = FeedingRecord.documentId(
          petId: pet.id,
          scheduleId: schedule.id,
          date: now,
        );
        final reference = _history(userId).doc(id);
        await _firestore.runTransaction((transaction) async {
          final currentPet = await transaction.get(
            schedule.reference.parent.parent!,
          );
          final currentSchedule = await transaction.get(schedule.reference);
          final existing = await transaction.get(reference);
          if (!currentPet.exists ||
              !currentSchedule.exists ||
              !FeedingSchedule.fromDocument(currentSchedule).occursOn(now)) {
            return;
          }
          final scheduledTime = currentSchedule.data()!['time'] as String;
          if (existing.exists) {
            if (existing.data()?['status'] == 'pending' &&
                existing.data()?['scheduledTime'] != scheduledTime) {
              transaction.update(reference, {'scheduledTime': scheduledTime});
            }
            return;
          }
          transaction.set(reference, {
            'id': id,
            'userId': userId,
            'petId': pet.id,
            'petName': currentPet.data()!['name'],
            'scheduleId': schedule.id,
            'scheduledTime': scheduledTime,
            'dateKey': dateKey,
            'status': 'pending',
            'fedAt': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
      }
    } on FirebaseException catch (exception) {
      throw FeedingHistoryFailure.fromFirebase(exception);
    }
  }

  Future<void> ensureTodayForAllPets(String userId) async {
    try {
      final pets = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pets')
          .get();
      for (final document in pets.docs) {
        await ensureTodayForPet(userId, Pet.fromDocument(document));
      }
    } on FirebaseException catch (exception) {
      throw FeedingHistoryFailure.fromFirebase(exception);
    }
  }

  Future<void> markAsFed({
    required String userId,
    required Pet pet,
    required String scheduleId,
    required String scheduledTime,
    double grams = 0,
    String food = '',
  }) async {
    if (!grams.isFinite ||
        grams < 0 ||
        grams > 10000 ||
        food.trim().length > 80) {
      throw const FeedingHistoryFailure('Revisa la cantidad y el alimento.');
    }
    final now = DateTime.now();
    final dateKey = FeedingRecord.dateKeyFor(now);
    final id = FeedingRecord.documentId(
      petId: pet.id,
      scheduleId: scheduleId,
      date: now,
    );
    final reference = _history(userId).doc(id);

    try {
      await _firestore.runTransaction((transaction) async {
        final petReference = _firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(pet.id);
        final currentPet = await transaction.get(petReference);
        final schedule = await transaction.get(
          petReference.collection('feedingSchedules').doc(scheduleId),
        );
        final snapshot = await transaction.get(reference);
        if (!currentPet.exists ||
            !schedule.exists ||
            !FeedingSchedule.fromDocument(schedule).occursOn(now)) {
          throw const FeedingHistoryFailure(
            'La mascota o el horario ya no están disponibles.',
          );
        }
        if (snapshot.exists && snapshot.data()?['status'] == 'fed') {
          return;
        }
        if (snapshot.exists) {
          transaction.update(reference, {
            'status': 'fed',
            'fedAt': FieldValue.serverTimestamp(),
            'grams': grams,
            'food': food.trim(),
          });
          return;
        }
        transaction.set(reference, {
          'id': id,
          'userId': userId,
          'petId': pet.id,
          'petName': currentPet.data()!['name'],
          'scheduleId': scheduleId,
          'scheduledTime': schedule.data()!['time'],
          'dateKey': dateKey,
          'status': 'fed',
          'fedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'grams': grams,
          'food': food.trim(),
        });
      });
    } on FirebaseException catch (exception) {
      throw FeedingHistoryFailure.fromFirebase(exception);
    }
  }

  CollectionReference<Map<String, dynamic>> _history(String userId) =>
      _firestore.collection('users').doc(userId).collection('feedingHistory');

  Future<void> addManual({
    required String userId,
    required Pet pet,
    required double grams,
    required String food,
  }) async {
    if (!grams.isFinite ||
        grams <= 0 ||
        grams > 10000 ||
        food.trim().length > 80) {
      throw const FeedingHistoryFailure(
        'Escribe una cantidad entre 0 y 10000 gramos.',
      );
    }
    final reference = _history(userId).doc();
    final now = DateTime.now();
    final petRef = _firestore.doc('users/$userId/pets/${pet.id}');
    await _firestore
        .runTransaction((tx) async {
          final snapshot = await tx.get(petRef);
          if (!snapshot.exists) {
            throw const FeedingHistoryFailure(
              'La mascota ya no está disponible.',
            );
          }
          tx.set(reference, {
            'id': reference.id,
            'userId': userId,
            'petId': pet.id,
            'petName': snapshot.data()!['name'],
            'scheduleId': 'manual',
            'scheduledTime':
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            'dateKey': FeedingRecord.dateKeyFor(now),
            'status': 'fed',
            'manual': true,
            'grams': grams,
            'food': food.trim(),
            'fedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 15));
  }
}
