import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/providers/pet_providers.dart';
import 'package:petreminder_user/providers/feeding_schedule_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final notificationSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final userId = ref.watch(careOwnerIdProvider);
  if (userId == null) {
    return;
  }
  final pets = ref.watch(petsProvider).value;
  if (pets == null) return;
  for (final pet in pets) {
    ref.watch(feedingSchedulesProvider(pet.id));
  }
  await ref
      .watch(notificationServiceProvider)
      .syncAllForUser(firestore: ref.watch(firestoreProvider), userId: userId);
});
