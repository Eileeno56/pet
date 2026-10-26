import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';

final syncStatusProvider = StreamProvider.autoDispose<String?>((ref) {
  final owner = ref.watch(careOwnerIdProvider);
  if (owner == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users/$owner/pets')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        if (snapshot.metadata.hasPendingWrites) {
          return 'Hay cambios pendientes de sincronizar. Mantén tu conexión para confirmarlos.';
        }
        if (snapshot.metadata.isFromCache) {
          return 'Mostrando datos de este dispositivo. Revisa tu conexión si no se actualizan.';
        }
        return null;
      });
});
