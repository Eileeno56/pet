import 'dart:io';
import 'package:petreminder_user/features/pets/presentation/pet_care_screen.dart';
import 'package:petreminder_user/providers/pet_care_providers.dart';
import 'package:petreminder_user/features/pets/presentation/schedule_editor.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petreminder_user/core/errors/feeding_history_failure.dart';
import 'package:petreminder_user/core/errors/feeding_schedule_failure.dart';
import 'package:petreminder_user/core/router/app_routes.dart';
import 'package:petreminder_user/models/feeding_record.dart';
import 'package:petreminder_user/models/feeding_schedule.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/feeding_history_providers.dart';
import 'package:petreminder_user/providers/feeding_schedule_providers.dart';
import 'package:petreminder_user/providers/pet_providers.dart';

class PetDetailScreen extends ConsumerWidget {
  const PetDetailScreen({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider);
    final current = pets.value?.where((item) => item.id == pet.id).firstOrNull;
    if (pets.hasValue && !pets.isLoading && current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mascota no disponible')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Volver al inicio'),
          ),
        ),
      );
    }
    return _PetDetailView(pet: current ?? pet);
  }
}

class _PetDetailView extends ConsumerWidget {
  const _PetDetailView({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(feedingSchedulesProvider(pet.id));
    ref.watch(carePlanProvider(pet.id));
    final scheduleOperation = ref.watch(feedingScheduleControllerProvider);
    final historyOperation = ref.watch(feedingHistoryControllerProvider);
    final history = ref.watch(feedingHistoryProvider);
    ref.watch(ensureTodayForPetProvider(pet));
    final photoPath = ref.watch(petPhotoPathProvider(pet.id)).value;
    final todayKey = FeedingRecord.dateKeyFor(DateTime.now());
    final recordsBySchedule = {
      for (final record in history.value ?? const <FeedingRecord>[])
        if (record.petId == pet.id && record.dateKey == todayKey)
          record.scheduleId: record,
    };

    ref.listen(feedingScheduleControllerProvider, (previous, next) {
      if (!next.hasError || previous?.error == next.error) {
        return;
      }
      final error = next.error;
      final message = error is FeedingScheduleFailure
          ? error.message
          : 'No se pudo completar la acción con el horario.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    ref.listen(feedingHistoryControllerProvider, (previous, next) {
      if (!next.hasError || previous?.error == next.error) {
        return;
      }
      final error = next.error;
      final message = error is FeedingHistoryFailure
          ? error.message
          : 'No se pudo registrar la alimentación.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    final isBusy = scheduleOperation.isLoading || historyOperation.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            tooltip: 'Editar mascota',
            onPressed: () =>
                context.push(AppRoutes.editPet(pet.id), extra: pet),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _PetSummary(pet: pet, photoPath: photoPath),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: const Text('Alimento y ficha médica'),
                    subtitle: const Text('Meta diaria, porciones y cuidados'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/pets/${pet.id}/care', extra: pet),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => showMealDialog(context, ref, pet),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Registrar comida manual'),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Horarios de alimentación',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Agregar horario',
                      onPressed: isBusy
                          ? null
                          : () => _addSchedule(
                              context,
                              ref,
                              schedules.value ?? const [],
                            ),
                      icon: const Icon(Icons.add_alarm_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                schedules.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => _ScheduleError(
                    onRetry: () =>
                        ref.invalidate(feedingSchedulesProvider(pet.id)),
                  ),
                  data: (items) => items.isEmpty
                      ? _EmptySchedules(
                          onAdd: () => _addSchedule(context, ref, items),
                        )
                      : Column(
                          children: [
                            for (final schedule in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ScheduleTile(
                                  schedule: schedule,
                                  record: recordsBySchedule[schedule.id],
                                  disabled: isBusy,
                                  onToggle: (active) =>
                                      _toggleSchedule(ref, schedule, active),
                                  onEdit: () => _editSchedule(
                                    context,
                                    ref,
                                    schedule,
                                    items,
                                  ),
                                  onDelete: () =>
                                      _deleteSchedule(context, ref, schedule),
                                  onFed: () => showMealDialog(
                                    context,
                                    ref,
                                    pet,
                                    schedule: schedule,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isBusy
            ? null
            : () => _addSchedule(context, ref, schedules.value ?? const []),
        icon: const Icon(Icons.add_alarm_outlined),
        label: const Text('Agregar horario'),
      ),
    );
  }

  Future<void> _addSchedule(
    BuildContext context,
    WidgetRef ref,
    List<FeedingSchedule> schedules,
  ) async {
    final draft = await showDialog<ScheduleDraft>(
      context: context,
      builder: (_) => const ScheduleEditor(),
    );
    if (draft == null || !context.mounted) return;
    if (_hasDuplicate(schedules, draft.time, days: draft.weekdays)) {
      _showDuplicateMessage(context);
      return;
    }
    final created = await ref
        .read(feedingScheduleControllerProvider.notifier)
        .create(
          pet: pet,
          time: draft.time,
          label: draft.label,
          foodType: draft.foodType,
          notes: draft.notes,
          weekdays: draft.weekdays,
        );
    if (created) {
      ref.invalidate(ensureTodayForPetProvider(pet));
    }
  }

  Future<void> _editSchedule(
    BuildContext context,
    WidgetRef ref,
    FeedingSchedule schedule,
    List<FeedingSchedule> schedules,
  ) async {
    final draft = await showDialog<ScheduleDraft>(
      context: context,
      builder: (_) => ScheduleEditor(schedule: schedule),
    );
    if (draft == null || !context.mounted) return;
    if (_hasDuplicate(
      schedules,
      draft.time,
      exceptId: schedule.id,
      days: draft.weekdays,
    )) {
      _showDuplicateMessage(context);
      return;
    }
    final updated = await ref
        .read(feedingScheduleControllerProvider.notifier)
        .updateTime(
          pet: pet,
          schedule: schedule,
          time: draft.time,
          label: draft.label,
          foodType: draft.foodType,
          notes: draft.notes,
          weekdays: draft.weekdays,
        );
    if (updated) {
      ref.invalidate(ensureTodayForPetProvider(pet));
    }
  }

  Future<void> _toggleSchedule(
    WidgetRef ref,
    FeedingSchedule schedule,
    bool active,
  ) async {
    final updated = await ref
        .read(feedingScheduleControllerProvider.notifier)
        .setActive(pet: pet, schedule: schedule, active: active);
    if (updated && active) {
      ref.invalidate(ensureTodayForPetProvider(pet));
    }
  }

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    FeedingSchedule schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar horario'),
        content: Text('¿Deseas eliminar el horario de las ${schedule.time}?'),
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
    if (confirmed != true) {
      return;
    }
    await ref
        .read(feedingScheduleControllerProvider.notifier)
        .delete(petId: pet.id, scheduleId: schedule.id);
  }

  bool _hasDuplicate(
    List<FeedingSchedule> schedules,
    String time, {
    String? exceptId,
    List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  }) => schedules.any(
    (schedule) =>
        schedule.id != exceptId &&
        schedule.time == time &&
        schedule.weekdays.any(days.contains),
  );

  void _showDuplicateMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ese horario ya está registrado.')),
    );
  }
}

class _PetSummary extends StatelessWidget {
  const _PetSummary({required this.pet, required this.photoPath});

  final Pet pet;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 112,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: photoPath == null
                  ? const Icon(Icons.pets_rounded, size: 48)
                  : Image.file(
                      File(photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.pets_rounded, size: 48),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${pet.speciesLabel}${pet.breed.isEmpty ? '' : ' · ${pet.breed}'}',
              ),
              Text(pet.ageLabel),
              if (pet.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  pet.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.schedule,
    required this.record,
    required this.disabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onFed,
  });

  final FeedingSchedule schedule;
  final FeedingRecord? record;
  final bool disabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onFed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              schedule.active
                  ? Icons.alarm_on_outlined
                  : Icons.alarm_off_outlined,
            ),
            title: Text(
              '${schedule.time} · ${schedule.displayLabel}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${schedule.foodType} · ${schedule.frequencyLabel}\n$_statusLabel${schedule.notes.isEmpty ? "" : "\n${schedule.notes}"}',
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Switch(
                value: schedule.active,
                onChanged: disabled ? null : onToggle,
              ),
              IconButton(
                tooltip: 'Editar horario',
                onPressed: disabled ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Eliminar horario',
                onPressed: disabled ? null : onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (schedule.occursOn(DateTime.now()) && record?.isFed != true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.center,
                child: FilledButton.icon(
                  onPressed: disabled ? null : onFed,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Ya comió'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _statusLabel {
    if (!schedule.active) {
      return 'Desactivado';
    }
    if (!schedule.occursOn(DateTime.now())) return 'No corresponde hoy';
    return record?.isFed == true ? 'Alimentada' : 'Pendiente';
  }
}

class _EmptySchedules extends StatelessWidget {
  const _EmptySchedules({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.schedule_outlined, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Esta mascota todavía no tiene horarios.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_alarm_outlined),
            label: const Text('Agregar horario'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleError extends StatelessWidget {
  const _ScheduleError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('No se pudieron cargar los horarios.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
