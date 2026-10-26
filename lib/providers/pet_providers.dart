import 'package:petreminder_user/providers/care_space_providers.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/core/errors/pet_failure.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/providers/notification_providers.dart';
import 'package:petreminder_user/repositories/pet_repository.dart';
import 'package:petreminder_user/services/pet_photo_service.dart';

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepository(ref.watch(firestoreProvider)),
);

final petPhotoServiceProvider = Provider<PetPhotoService>(
  (ref) => PetPhotoService(),
);

final petsProvider = StreamProvider.autoDispose<List<Pet>>((ref) {
  final userId = ref.watch(careOwnerIdProvider);
  if (userId == null) {
    return Stream.value(const []);
  }
  return ref.watch(petRepositoryProvider).watchPets(userId);
});

final petPhotoPathProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, petId) {
    final userId = ref.watch(careOwnerIdProvider);
    if (userId == null) {
      return Future.value(null);
    }
    return ref
        .watch(petPhotoServiceProvider)
        .findPhoto(userId: userId, petId: petId);
  },
);

final petControllerProvider = AsyncNotifierProvider<PetController, void>(
  PetController.new,
);

class PetController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String?> createPet({
    required PetInput input,
    String? photoPath,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final ownerId = ref.read(careOwnerIdProvider);
      if (user == null || ownerId == null) {
        throw const PetFailure('Debes iniciar sesión para agregar mascotas.');
      }

      final petId = await ref
          .read(petRepositoryProvider)
          .createPet(ownerId, input)
          .timeout(const Duration(seconds: 15));
      if (photoPath != null) {
        await ref
            .read(petPhotoServiceProvider)
            .savePhoto(userId: ownerId, petId: petId, sourcePath: photoPath);
        ref.invalidate(petPhotoPathProvider(petId));
      }
      state = const AsyncData(null);
      return petId;
    } catch (error, stackTrace) {
      state = AsyncError(
        error is TimeoutException
            ? const PetFailure(
                'No se confirmó el cambio. Revisa tu conexión y consulta tus mascotas antes de reintentar.',
              )
            : error,
        stackTrace,
      );
      return null;
    }
  }

  Future<bool> updatePet({
    required String petId,
    required PetInput input,
    String? photoPath,
    bool removePhoto = false,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final ownerId = ref.read(careOwnerIdProvider);
      if (user == null || ownerId == null) {
        throw const PetFailure('Debes iniciar sesión para editar mascotas.');
      }

      await ref
          .read(petRepositoryProvider)
          .updatePet(ownerId, petId, input)
          .timeout(const Duration(seconds: 15));
      final photoService = ref.read(petPhotoServiceProvider);
      if (removePhoto) {
        await photoService.deletePhoto(userId: ownerId, petId: petId);
      } else if (photoPath != null) {
        await photoService.savePhoto(
          userId: ownerId,
          petId: petId,
          sourcePath: photoPath,
        );
      }
      ref.invalidate(petPhotoPathProvider(petId));
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        error is TimeoutException
            ? const PetFailure(
                'No se confirmó el cambio. Revisa tu conexión y consulta tus mascotas antes de reintentar.',
              )
            : error,
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> deletePet(String petId) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final ownerId = ref.read(careOwnerIdProvider);
      if (user == null || ownerId == null) {
        throw const PetFailure('Debes iniciar sesión para eliminar mascotas.');
      }

      final schedules = await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(ownerId)
          .collection('pets')
          .doc(petId)
          .collection('feedingSchedules')
          .get()
          .timeout(const Duration(seconds: 10));
      await ref
          .read(petRepositoryProvider)
          .deletePet(ownerId, petId)
          .timeout(const Duration(seconds: 20));
      final notifications = ref.read(notificationServiceProvider);
      for (final schedule in schedules.docs) {
        await notifications.cancelSchedule(
          petId: petId,
          scheduleId: schedule.id,
        );
      }
      await ref
          .read(petPhotoServiceProvider)
          .deletePhoto(userId: ownerId, petId: petId);
      ref.invalidate(petPhotoPathProvider(petId));
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        error is TimeoutException
            ? const PetFailure(
                'No se confirmó el cambio. Revisa tu conexión y consulta tus mascotas antes de reintentar.',
              )
            : error,
        stackTrace,
      );
      return false;
    }
  }
}
