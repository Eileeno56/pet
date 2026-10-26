import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedingStatus { pending, fed }

class FeedingRecord {
  const FeedingRecord({
    required this.id,
    required this.userId,
    required this.petId,
    required this.petName,
    required this.scheduleId,
    required this.scheduledTime,
    required this.dateKey,
    required this.status,
    required this.fedAt,
    required this.createdAt,
    this.manual = false,
    this.grams = 0,
    this.food = '',
  });

  final String id;
  final String userId;
  final String petId;
  final String petName;
  final String scheduleId;
  final String scheduledTime;
  final String dateKey;
  final FeedingStatus status;
  final DateTime? fedAt;
  final DateTime createdAt;
  final bool manual;
  final double grams;
  final String food;

  bool get isFed => status == FeedingStatus.fed;

  factory FeedingRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final fedAt = data['fedAt'];
    final createdAt = data['createdAt'];

    return FeedingRecord(
      id: document.id,
      manual: data['manual'] == true,
      grams: (data['grams'] as num?)?.toDouble() ?? 0,
      food: data['food'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      petId: data['petId'] as String? ?? '',
      petName: data['petName'] as String? ?? '',
      scheduleId: data['scheduleId'] as String? ?? '',
      scheduledTime: data['scheduledTime'] as String? ?? '00:00',
      dateKey: data['dateKey'] as String? ?? '',
      status: data['status'] == 'fed'
          ? FeedingStatus.fed
          : FeedingStatus.pending,
      fedAt: fedAt is Timestamp ? fedAt.toDate() : null,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String dateKeyFor(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static String documentId({
    required String petId,
    required String scheduleId,
    required DateTime date,
  }) => '${petId}_${scheduleId}_${dateKeyFor(date).replaceAll('-', '')}';
}
