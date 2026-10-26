import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/models/care_plan.dart';
import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';

final carePlanProvider = StreamProvider.autoDispose.family<CarePlan, String>((
  ref,
  petId,
) {
  final owner = ref.watch(careOwnerIdProvider);
  if (owner == null) return Stream.value(const CarePlan());
  return ref
      .watch(firestoreProvider)
      .doc('users/$owner/pets/$petId/carePlan/diet')
      .snapshots()
      .map((d) => CarePlan.fromMap(d.data()));
});

final medicalRecordsProvider = StreamProvider.autoDispose
    .family<List<MedicalRecord>, String>((ref, petId) {
      final owner = ref.watch(careOwnerIdProvider);
      if (owner == null) return Stream.value([]);
      return ref
          .watch(firestoreProvider)
          .collection('users/$owner/pets/$petId/medicalRecords')
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map(MedicalRecord.fromDocument).toList());
    });

final petCareRepositoryProvider = Provider(
  (ref) => PetCareRepository(ref.watch(firestoreProvider)),
);

class PetCareRepository {
  PetCareRepository(this.db);
  final FirebaseFirestore db;
  Future<void> savePlan(String owner, String petId, CarePlan plan) async {
    if (!plan.dailyGrams.isFinite ||
        plan.dailyGrams < 0 ||
        plan.dailyGrams > 10000 ||
        !plan.weightKg.isFinite ||
        plan.weightKg < 0 ||
        plan.weightKg > 1000 ||
        plan.mealsPerDay < 1 ||
        plan.mealsPerDay > 12 ||
        plan.food.trim().length > 80 ||
        plan.notes.trim().length > 500) {
      throw ArgumentError('Revisa las cantidades y el número de comidas.');
    }
    await db
        .doc('users/$owner/pets/$petId/carePlan/diet')
        .set(plan.toMap())
        .timeout(const Duration(seconds: 15));
  }

  Future<void> saveMedical(
    String owner,
    String petId,
    MedicalRecord record,
  ) async {
    if (record.title.trim().length < 2 ||
        record.title.trim().length > 80 ||
        record.notes.trim().length > 1000 ||
        ![
          'Consulta',
          'Vacuna',
          'Desparasitación',
          'Tratamiento',
          'Otro',
        ].contains(record.kind)) {
      throw ArgumentError('Revisa los datos de la ficha médica.');
    }
    final collection = db.collection('users/$owner/pets/$petId/medicalRecords');
    final reference = record.id.isEmpty
        ? collection.doc()
        : collection.doc(record.id);
    await reference
        .set({
          'title': record.title.trim(),
          'kind': record.kind,
          'date': Timestamp.fromDate(record.date),
          'notes': record.notes.trim(),
          'nextDate': record.nextDate == null
              ? null
              : Timestamp.fromDate(record.nextDate!),
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> deleteMedical(String owner, String petId, String recordId) => db
      .doc('users/$owner/pets/$petId/medicalRecords/$recordId')
      .delete()
      .timeout(const Duration(seconds: 15));
}
