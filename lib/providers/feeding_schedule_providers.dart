import 'package:petreminder_user/providers/care_space_providers.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/core/errors/feeding_schedule_failure.dart';
import 'package:petreminder_user/models/feeding_schedule.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/repositories/feeding_schedule_repository.dart';

final feedingScheduleRepositoryProvider = Provider<FeedingScheduleRepository>(
  (ref) => FeedingScheduleRepository(ref.watch(firestoreProvider)),
);

final feedingSchedulesProvider = StreamProvider.autoDispose
    .family<List<FeedingSchedule>, String>((ref, petId) {
      final userId = ref.watch(careOwnerIdProvider);
      if (userId == null) {
        return Stream.value(const []);
      }
      return ref
          .watch(feedingScheduleRepositoryProvider)
          .watchSchedules(userId, petId);
    });

final feedingScheduleControllerProvider =
    AsyncNotifierProvider<FeedingScheduleController, void>(
      FeedingScheduleController.new,
    );

class FeedingScheduleController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> create({
    required Pet pet,
    required String time,
    String label = '',
    String foodType = 'Alimento',
    String notes = '',
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) {
    return _run((userId, repository) async {
      await repository.createSchedule(
        userId,
        pet.id,
        time,
        label: label,
        foodType: foodType,
        notes: notes,
        weekdays: weekdays,
      );
    });
  }

  Future<bool> updateTime({
    required Pet pet,
    required FeedingSchedule schedule,
    required String time,
    String label = '',
    String foodType = 'Alimento',
    String notes = '',
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) {
    return _run((userId, repository) async {
      await repository.updateTime(
        userId,
        pet.id,
        schedule.id,
        time,
        label: label,
        foodType: foodType,
        notes: notes,
        weekdays: weekdays,
      );
    });
  }

  Future<bool> setActive({
    required Pet pet,
    required FeedingSchedule schedule,
    required bool active,
  }) {
    return _run((userId, repository) async {
      await repository.setActive(userId, pet.id, schedule.id, active);
    });
  }

  Future<bool> delete({required String petId, required String scheduleId}) {
    return _run((userId, repository) async {
      await repository.deleteSchedule(userId, petId, scheduleId);
    });
  }

  Future<bool> _run(
    Future<void> Function(String userId, FeedingScheduleRepository repository)
    operation,
  ) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw const FeedingScheduleFailure(
          'Debes iniciar sesión para administrar horarios.',
        );
      }
      await operation(
        ref.read(careOwnerIdProvider)!,
        ref.read(feedingScheduleRepositoryProvider),
      ).timeout(const Duration(seconds: 15));
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(
        error is TimeoutException
            ? const FeedingScheduleFailure(
                'No se confirmó el cambio. Revisa tu conexión y consulta el horario antes de reintentar.',
              )
            : error,
        stackTrace,
      );
      return false;
    }
  }
}
