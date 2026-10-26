import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingSchedule {
  const FeedingSchedule({
    required this.id,
    required this.time,
    required this.active,
    required this.createdAt,
    this.label = '',
    this.foodType = 'Alimento',
    this.notes = '',
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
  });

  final String id;
  final String time;
  final bool active;
  final DateTime createdAt;
  final String label;
  final String foodType;
  final String notes;
  final List<int> weekdays;

  bool occursOn(DateTime date) => active && weekdays.contains(date.weekday);
  DateTime nextDate(DateTime now) {
    for (var offset = 0; offset <= 7; offset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + offset,
        minutesSinceMidnight ~/ 60,
        minutesSinceMidnight % 60,
      );
      if (occursOn(candidate) && candidate.isAfter(now)) return candidate;
    }
    return now.add(const Duration(days: 8));
  }

  String get displayLabel => label.isEmpty ? 'Comida' : label;
  String get frequencyLabel => weekdays.length == 7
      ? 'Todos los días'
      : weekdays
            .map(
              (day) => const [
                'Lun',
                'Mar',
                'Mié',
                'Jue',
                'Vie',
                'Sáb',
                'Dom',
              ][day - 1],
            )
            .join(', ');

  static bool validWeekdays(List<int> days) =>
      days.isNotEmpty &&
      days.length <= 7 &&
      days.toSet().length == days.length &&
      days.every((d) => d >= 1 && d <= 7);

  Map<String, dynamic> get details => {
    'label': label.trim(),
    'foodType': foodType.trim(),
    'notes': notes.trim(),
    'weekdays': weekdays,
  };

  int get minutesSinceMidnight {
    final parts = time.split(':');
    return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
  }

  factory FeedingSchedule.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];

    return FeedingSchedule(
      id: document.id,
      time: data['time'] as String? ?? '00:00',
      active: data['active'] as bool? ?? true,
      label: data['label'] as String? ?? '',
      foodType: data['foodType'] as String? ?? 'Alimento',
      notes: data['notes'] as String? ?? '',
      weekdays:
          (data['weekdays'] as List?)?.cast<int>() ??
          const [1, 2, 3, 4, 5, 6, 7],
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static bool isValidTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      return false;
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }
}
