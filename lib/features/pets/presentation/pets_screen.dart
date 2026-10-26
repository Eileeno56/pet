import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petreminder_user/core/errors/pet_failure.dart';
import 'package:petreminder_user/core/router/app_routes.dart';
import 'package:petreminder_user/models/feeding_record.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/feeding_history_providers.dart';
import 'package:petreminder_user/providers/feeding_schedule_providers.dart';
import 'package:petreminder_user/providers/pet_providers.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider);
    final operation = ref.watch(petControllerProvider);
    ref.watch(ensureTodayForAllPetsProvider);

    ref.listen(petControllerProvider, (previous, next) {
      if (!next.hasError || previous?.error == next.error) {
        return;
      }
      final error = next.error;
      final message = error is PetFailure
          ? error.message
          : 'No se pudo completar la acción.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    return Scaffold(
      appBar: AppBar(title: const Text('PetReminder')),
      body: SafeArea(
        child: pets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              _ErrorState(onRetry: () => ref.invalidate(petsProvider)),
          data: (items) => items.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: () async => ref.refresh(petsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) => _PetCard(
                      pet: items[index],
                      disabled: operation.isLoading,
                      onOpen: () => context.push(
                        AppRoutes.petDetail(items[index].id),
                        extra: items[index],
                      ),
                      onEdit: () => context.push(
                        AppRoutes.editPet(items[index].id),
                        extra: items[index],
                      ),
                      onDelete: () =>
                          _confirmDelete(context, ref, items[index]),
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: operation.isLoading
            ? null
            : () => context.push(AppRoutes.addPet),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar mascota'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Pet pet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
          '¿Deseas eliminar a ${pet.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    final deleted = await ref
        .read(petControllerProvider.notifier)
        .deletePet(pet.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${pet.name} fue eliminado.')));
    }
  }
}

class _PetCard extends ConsumerWidget {
  const _PetCard({
    required this.pet,
    required this.disabled,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Pet pet;
  final bool disabled;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoPath = ref.watch(petPhotoPathProvider(pet.id)).value;
    final schedules = ref.watch(feedingSchedulesProvider(pet.id)).value ?? [];
    final activeSchedules = schedules
        .where((schedule) => schedule.active)
        .toList();
    final now = DateTime.now();
    activeSchedules.sort((a, b) => a.nextDate(now).compareTo(b.nextDate(now)));
    final next = activeSchedules.isEmpty
        ? null
        : activeSchedules.first.nextDate(now);
    final nextMeal = next == null
        ? 'Sin configurar'
        : '${next.day == now.day && next.month == now.month ? "Hoy" : "${next.day}/${next.month}"} ${activeSchedules.first.time}';
    final todayKey = FeedingRecord.dateKeyFor(DateTime.now());
    final activeIds = activeSchedules
        .where((s) => s.occursOn(now))
        .map((schedule) => schedule.id)
        .toSet();
    final todayRecords = (ref.watch(feedingHistoryProvider).value ?? const [])
        .where(
          (record) =>
              record.petId == pet.id &&
              record.dateKey == todayKey &&
              activeIds.contains(record.scheduleId),
        )
        .toList();
    final status = activeIds.isEmpty
        ? 'Sin comidas hoy'
        : todayRecords.isNotEmpty &&
              todayRecords.every((record) => record.isFed)
        ? 'Alimentada'
        : 'Pendiente';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox.square(
                  dimension: 96,
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: photoPath == null
                        ? const Icon(Icons.pets_rounded, size: 38)
                        : Image.file(
                            File(photoPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.pets_rounded, size: 38),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet.speciesLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined, size: 17),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Próxima comida: $nextMeal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_outlined, size: 17),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Estado: $status',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PetAction>(
                tooltip: 'Opciones de ${pet.name}',
                enabled: !disabled,
                onSelected: (action) {
                  switch (action) {
                    case _PetAction.edit:
                      onEdit();
                    case _PetAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _PetAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _PetAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Eliminar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PetAction { edit, delete }

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes mascotas',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega la primera para comenzar.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 52),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar tus mascotas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
