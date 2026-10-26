import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petreminder_user/providers/notification_providers.dart';
import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:petreminder_user/providers/sync_status_provider.dart';

class AppShellScreen extends ConsumerWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationSyncProvider);
    ref.listen(selectedMembershipProvider, (_, next) {
      if (next.value == false) {
        ref.read(careSpaceSelectionProvider.notifier).select(null);
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El acceso compartido ya no está disponible. Volviste a tus mascotas.',
            ),
          ),
        );
      }
    });
    final syncMessage = ref.watch(syncStatusProvider).value;
    final shared = ref.watch(careSpaceSelectionProvider) != null;

    return Scaffold(
      body: Column(
        children: [
          if (notifications.hasError)
            Material(
              color: const Color(0xFFFFF3D8),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        'No se pudieron actualizar los avisos. Revisa tu conexión y los permisos de notificaciones.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(notificationSyncProvider),
                        child: const Text('Reintentar avisos'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (shared)
            Material(
              color: const Color(0xFFF0EAF8),
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.diversity_1_outlined),
                  title: const Text('Espacio compartido'),
                  trailing: TextButton(
                    onPressed: () => ref
                        .read(careSpaceSelectionProvider.notifier)
                        .select(null),
                    child: const Text('Mis mascotas'),
                  ),
                ),
              ),
            ),
          if (syncMessage != null)
            Material(
              color: const Color(0xFFFFF3D8),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(syncMessage, textAlign: TextAlign.center),
                ),
              ),
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
