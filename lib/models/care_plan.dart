import 'package:cloud_firestore/cloud_firestore.dart';

class CarePlan {
  const CarePlan({
    this.dailyGrams = 0,
    this.weightKg = 0,
    this.mealsPerDay = 2,
    this.food = '',
    this.notes = '',
  });
  final double dailyGrams, weightKg;
  final int mealsPerDay;
  final String food, notes;
  double get gramsPerMeal => dailyGrams / mealsPerDay;
  double progress(double consumed) =>
      dailyGrams <= 0 ? 0 : (consumed / dailyGrams).clamp(0, 1);
  Map<String, dynamic> toMap() => {
    'dailyGrams': dailyGrams,
    'weightKg': weightKg,
    'mealsPerDay': mealsPerDay,
    'food': food.trim(),
    'notes': notes.trim(),
  };
  factory CarePlan.fromMap(Map<String, dynamic>? d) => CarePlan(
    dailyGrams: (d?['dailyGrams'] as num?)?.toDouble() ?? 0,
    weightKg: (d?['weightKg'] as num?)?.toDouble() ?? 0,
    mealsPerDay: (d?['mealsPerDay'] as num?)?.toInt() ?? 2,
    food: d?['food'] as String? ?? '',
    notes: d?['notes'] as String? ?? '',
  );
}

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.title,
    required this.kind,
    required this.date,
    required this.notes,
    this.nextDate,
  });
  final String id, title, kind, notes;
  final DateTime date;
  final DateTime? nextDate;
  factory MedicalRecord.fromDocument(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data()!;
    return MedicalRecord(
      id: d.id,
      title: data['title'] as String,
      kind: data['kind'] as String,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String,
      nextDate: (data['nextDate'] as Timestamp?)?.toDate(),
    );
  }
}
