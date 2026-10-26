import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/models/feeding_record.dart';
import 'package:petreminder_user/providers/feeding_history_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _status = 'Todas';
  String? _petId;
  DateTimeRange? _range;
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(feedingHistoryProvider);
    final ensureState = ref.watch(ensureTodayForAllPetsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _HistoryError(
                onRetry: () {
                  ref.invalidate(ensureTodayForAllPetsProvider);
                  ref.invalidate(feedingHistoryProvider);
                },
              ),
              data: (records) {
                if (ensureState.isLoading && records.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (records.isEmpty) return const _EmptyHistory();
                final pets = {for (final r in records) r.petId: r.petName};
                final selectedPet = pets.containsKey(_petId) ? _petId : null;
                final filtered = records.where((r) {
                  final date = DateTime.tryParse(r.dateKey);
                  return (selectedPet == null || r.petId == selectedPet) &&
                      (_status == 'Todas' ||
                          (_status == 'Realizadas' ? r.isFed : !r.isFed)) &&
                      (_range == null ||
                          (date != null &&
                              !date.isBefore(_range!.start) &&
                              !date.isAfter(_range!.end)));
                }).toList();
                final groups = <String, List<FeedingRecord>>{};
                for (final r in filtered) {
                  groups.putIfAbsent(r.dateKey, () => []).add(r);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Consulta tus comidas',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: [
                                for (final status in [
                                  'Todas',
                                  'Realizadas',
                                  'Pendientes',
                                ])
                                  ChoiceChip(
                                    label: Text(status),
                                    selected: _status == status,
                                    onSelected: (_) =>
                                        setState(() => _status = status),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              key: ValueKey(selectedPet),
                              initialValue: selectedPet ?? '',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Mascota',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Todas las mascotas'),
                                ),
                                ...pets.entries.map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _petId = value?.isEmpty == true
                                    ? null
                                    : value,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.date_range_outlined),
                              label: Text(
                                _range == null
                                    ? 'Elegir fechas'
                                    : '${_date(_range!.start)} — ${_date(_range!.end)}',
                              ),
                              onPressed: () async {
                                final range = await showDateRangePicker(
                                  context: context,
                                  initialDateRange: _range,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (range != null && mounted) {
                                  setState(() => _range = range);
                                }
                              },
                            ),
                            if (_range != null ||
                                selectedPet != null ||
                                _status != 'Todas')
                              TextButton(
                                onPressed: () => setState(() {
                                  _range = null;
                                  _petId = null;
                                  _status = 'Todas';
                                }),
                                child: const Text('Limpiar filtros'),
                              ),
                            Text(
                              '${filtered.length} registros',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hay comidas con estos filtros.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final entry in groups.entries)
                      _HistoryGroup(dateKey: entry.key, records: entry.value),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({required this.dateKey, required this.records});

  final String dateKey;
  final List<FeedingRecord> records;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              _dateLabel(dateKey),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final record in records)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFEFC),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(
                    record.isFed
                        ? Icons.check_circle_outline_rounded
                        : Icons.schedule_rounded,
                    color: record.isFed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    '${record.petName}${record.manual ? " · Manual" : ""}',
                  ),
                  subtitle: Text(
                    '${record.isFed ? '${record.scheduledTime} · Alimentada${_fedTime(record)}' : '${record.scheduledTime} · Pendiente'}'
                    '${record.grams > 0 ? '\n${record.grams.toStringAsFixed(1)} g' : ''}'
                    '${record.food.isEmpty ? '' : ' · ${record.food}'}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fedTime(FeedingRecord record) {
    final date = record.fedAt?.toLocal();
    if (date == null) {
      return '';
    }
    final time =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    return ' a las $time';
  }

  String _dateLabel(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(date).inDays;
    if (difference == 0) {
      return 'Hoy · ${date.day}/${date.month}/${date.year}';
    }
    if (difference == 1) {
      return 'Ayer · ${date.day}/${date.month}/${date.year}';
    }
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 56),
            SizedBox(height: 12),
            Text(
              'Todavía no hay alimentaciones programadas.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Abre una mascota para agregar horarios o registrar una comida manual.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      ),
    );
  }
}
