import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petreminder_user/core/errors/feeding_schedule_failure.dart';
import 'package:petreminder_user/core/firestore/delete_query.dart';
import 'package:petreminder_user/models/feeding_schedule.dart';

class FeedingScheduleRepository {
  FeedingScheduleRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<FeedingSchedule>> watchSchedules(String userId, String petId) {
    return _schedules(userId, petId)
        .orderBy('time')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FeedingSchedule.fromDocument).toList(),
        );
  }

  Future<String> createSchedule(
    String userId,
    String petId,
    String time, {
    String label = '',
    String foodType = 'Alimento',
    String notes = '',
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    _validate(time, label, foodType, notes, weekdays);
    final reference = _schedules(userId, petId).doc();
    try {
      await reference.set({
        'id': reference.id,
        'time': time,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'label': label.trim(),
        'foodType': foodType.trim(),
        'notes': notes.trim(),
        'weekdays': weekdays,
      });
      return reference.id;
    } on FirebaseException catch (exception) {
      throw FeedingScheduleFailure.fromFirebase(exception);
    }
  }

  Future<void> updateTime(
    String userId,
    String petId,
    String scheduleId,
    String time, {
    String label = '',
    String foodType = 'Alimento',
    String notes = '',
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    _validate(time, label, foodType, notes, weekdays);
    try {
      await _schedules(userId, petId).doc(scheduleId).update({
        'time': time,
        'label': label.trim(),
        'foodType': foodType.trim(),
        'notes': notes.trim(),
        'weekdays': weekdays,
      });
    } on FirebaseException catch (exception) {
      throw FeedingScheduleFailure.fromFirebase(exception);
    }
  }

  Future<void> setActive(
    String userId,
    String petId,
    String scheduleId,
    bool active,
  ) async {
    try {
      await _schedules(
        userId,
        petId,
      ).doc(scheduleId).update({'active': active});
    } on FirebaseException catch (exception) {
      throw FeedingScheduleFailure.fromFirebase(exception);
    }
  }

  Future<void> deleteSchedule(
    String userId,
    String petId,
    String scheduleId,
  ) async {
    try {
      await _schedules(userId, petId).doc(scheduleId).delete();
      await deleteQuery(
        _firestore,
        _firestore
            .collection('users')
            .doc(userId)
            .collection('feedingHistory')
            .where('petId', isEqualTo: petId)
            .where('scheduleId', isEqualTo: scheduleId),
      );
    } on FirebaseException catch (exception) {
      throw FeedingScheduleFailure.fromFirebase(exception);
    }
  }

  CollectionReference<Map<String, dynamic>> _schedules(
    String userId,
    String petId,
  ) => _firestore
      .collection('users')
      .doc(userId)
      .collection('pets')
      .doc(petId)
      .collection('feedingSchedules');

  void _validate(
    String time,
    String label,
    String foodType,
    String notes,
    List<int> days,
  ) {
    if (!FeedingSchedule.isValidTime(time) ||
        !FeedingSchedule.validWeekdays(days) ||
        label.trim().length > 40 ||
        foodType.trim().isEmpty ||
        foodType.trim().length > 60 ||
        notes.trim().length > 300) {
      throw const FeedingScheduleFailure(
        'Revisa la hora, los días y los datos del horario.',
      );
    }
  }
}
