import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/models/care_plan.dart';
import 'package:petreminder_user/models/feeding_record.dart';
import 'package:petreminder_user/models/feeding_schedule.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:petreminder_user/providers/feeding_history_providers.dart';
import 'package:petreminder_user/providers/pet_care_providers.dart';

String careDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String gramsLabel(double grams) => grams == grams.roundToDouble()
    ? grams.toInt().toString()
    : grams.toStringAsFixed(1);

class PetCareScreen extends ConsumerStatefulWidget {
  const PetCareScreen({required this.pet, super.key});
  final Pet pet;
  @override
  ConsumerState<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends ConsumerState<PetCareScreen> {
  bool _busy = false;
  Future<void> _run(Future<void> Function(String owner) action) async {
    final owner = ref.read(careOwnerIdProvider);
    if (owner == null) return;
    setState(() => _busy = true);
    try {
      await action(owner).timeout(const Duration(seconds: 18));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo confirmar el cambio. Revisa tu conexión y vuelve a consultar antes de reintentar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(carePlanProvider(widget.pet.id));
    final recordsState = ref.watch(feedingHistoryProvider);
    final medical = ref.watch(medicalRecordsProvider(widget.pet.id));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Cuidado de ${widget.pet.name}'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.restaurant_outlined), text: 'Alimento'),
              Tab(
                icon: Icon(Icons.medical_services_outlined),
                text: 'Ficha médica',
              ),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: TabBarView(
              children: [
                planState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _error(
                    () => ref.invalidate(carePlanProvider(widget.pet.id)),
                  ),
                  data: (plan) {
                    final today = FeedingRecord.dateKeyFor(DateTime.now());
                    final records = (recordsState.value ?? <FeedingRecord>[])
                        .where(
                          (r) =>
                              r.petId == widget.pet.id &&
                              r.dateKey == today &&
                              r.isFed,
                        )
                        .toList();
                    final consumed = records.fold<double>(
                      0,
                      (total, r) => total + r.grams,
                    );
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(Icons.pets_rounded, size: 42),
                                const SizedBox(height: 10),
                                Text(
                                  widget.pet.name,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                Text(
                                  '${widget.pet.speciesLabel} · ${widget.pet.ageLabel}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  plan.weightKg > 0
                                      ? 'Peso registrado: ${gramsLabel(plan.weightKg)} kg'
                                      : 'Peso sin registrar',
                                  textAlign: TextAlign.center,
                                ),
                                const Divider(height: 32),
                                Text(
                                  'Alimentación de hoy',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 14),
                                if (recordsState.isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (recordsState.hasError)
                                  const Text(
                                    'No se pudo consultar el consumo. Revisa tu conexión.',
                                    textAlign: TextAlign.center,
                                  )
                                else ...[
                                  Text(
                                    '${gramsLabel(consumed)} g registrados',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  if (plan.dailyGrams > 0) ...[
                                    LinearProgressIndicator(
                                      value: plan.progress(consumed),
                                      minHeight: 10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Meta: ${gramsLabel(plan.dailyGrams)} g · ${(consumed / plan.dailyGrams * 100).round()}%',
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      consumed >= plan.dailyGrams
                                          ? 'Cantidad diaria registrada'
                                          : 'Faltan ${gramsLabel(plan.dailyGrams - consumed)} g para la meta registrada',
                                      textAlign: TextAlign.center,
                                    ),
                                  ] else
                                    const Text(
                                      'Configura la cantidad diaria para ver tu avance.',
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => showMealDialog(
                                          context,
                                          ref,
                                          widget.pet,
                                        ),
                                  icon: const Icon(Icons.add_task),
                                  label: const Text('Registrar comida manual'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Plan de alimento',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  plan.food.isEmpty
                                      ? 'Alimento sin especificar'
                                      : plan.food,
                                  textAlign: TextAlign.center,
                                ),
                                if (plan.dailyGrams > 0)
                                  Text(
                                    '${gramsLabel(plan.dailyGrams)} g al día / ${plan.mealsPerDay} comidas = ${gramsLabel(plan.gramsPerMeal)} g por comida',
                                    textAlign: TextAlign.center,
                                  ),
                                if (plan.notes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      plan.notes,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Registra la cantidad diaria indicada para tu mascota por su veterinario o por la guía del alimento. El reparto por comida es una división de esa cantidad.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          final result =
                                              await showDialog<CarePlan>(
                                                context: context,
                                                builder: (_) =>
                                                    _PlanEditor(plan: plan),
                                              );
                                          if (result != null) {
                                            await _run(
                                              (owner) => ref
                                                  .read(
                                                    petCareRepositoryProvider,
                                                  )
                                                  .savePlan(
                                                    owner,
                                                    widget.pet.id,
                                                    result,
                                                  ),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Configurar plan y peso'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (final r in records)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.check_circle_outline),
                              title: Text(
                                '${gramsLabel(r.grams)} g · ${r.food.isEmpty ? "Alimento" : r.food}',
                              ),
                              subtitle: Text(
                                '${r.scheduledTime} · ${r.manual ? "Registro manual" : "Comida programada"}',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                medical.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _error(
                    () => ref.invalidate(medicalRecordsProvider(widget.pet.id)),
                  ),
                  data: (items) => ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Consultas, vacunas y cuidados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Guarda las indicaciones y fechas de atención de tu mascota.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _editMedical(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar registro médico'),
                      ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Todavía no hay registros médicos.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final item in items)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text('${item.kind} · ${careDate(item.date)}'),
                                if (item.notes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(item.notes),
                                  ),
                                if (item.nextDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Próxima fecha: ${careDate(item.nextDate!)}',
                                    ),
                                  ),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar registro médico',
                                      onPressed: _busy
                                          ? null
                                          : () => _editMedical(item),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar registro médico',
                                      onPressed: _busy
                                          ? null
                                          : () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                          title: const Text(
                                                            'Eliminar registro',
                                                          ),
                                                          content: Text(
                                                            '¿Eliminar ${item.title}?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancelar',
                                                              ),
                                                            ),
                                                            FilledButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Eliminar',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                              if (confirmed == true) {
                                                await _run(
                                                  (owner) => ref
                                                      .read(
                                                        petCareRepositoryProvider,
                                                      )
                                                      .deleteMedical(
                                                        owner,
                                                        widget.pet.id,
                                                        item.id,
                                                      ),
                                                );
                                              }
                                            },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }

  Widget _error(VoidCallback retry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'No se pudieron cargar los datos.',
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: retry, child: const Text('Reintentar')),
      ],
    ),
  );
  Future<void> _editMedical([MedicalRecord? record]) async {
    final result = await showDialog<MedicalRecord>(
      context: context,
      builder: (_) => _MedicalEditor(record: record),
    );
    if (result != null) {
      await _run(
        (owner) => ref
            .read(petCareRepositoryProvider)
            .saveMedical(owner, widget.pet.id, result),
      );
    }
  }
}

Future<void> showMealDialog(
  BuildContext context,
  WidgetRef ref,
  Pet pet, {
  FeedingSchedule? schedule,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MealEditor(pet: pet, schedule: schedule),
  );
}

class _MealEditor extends ConsumerStatefulWidget {
  const _MealEditor({required this.pet, this.schedule});
  final Pet pet;
  final FeedingSchedule? schedule;
  @override
  ConsumerState<_MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends ConsumerState<_MealEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _grams, _food;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final plan =
        ref.read(carePlanProvider(widget.pet.id)).value ?? const CarePlan();
    _grams = TextEditingController(
      text: plan.dailyGrams > 0 ? gramsLabel(plan.gramsPerMeal) : '',
    );
    _food = TextEditingController(
      text: plan.food.isNotEmpty ? plan.food : widget.schedule?.foodType ?? '',
    );
  }

  @override
  void dispose() {
    _grams.dispose();
    _food.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        widget.schedule == null
            ? 'Registrar comida manual'
            : 'Confirmar comida',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.pet.name, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextFormField(
                controller: _grams,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Cantidad consumida (g)',
                  helperText: widget.schedule == null
                      ? 'Escribe la cantidad realmente consumida.'
                      : 'Opcional. Déjala vacía si solo confirmarás la comida.',
                ),
                validator: (text) {
                  if ((text?.isEmpty ?? true) && widget.schedule != null) {
                    return null;
                  }
                  final n = double.tryParse((text ?? '').replaceAll(',', '.'));
                  return n == null || !n.isFinite || n <= 0 || n > 10000
                      ? 'Indica una cantidad mayor a 0 y hasta 10000 g.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _food,
                enabled: !_busy,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Alimento (opcional)',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() {
                    _busy = true;
                    _error = null;
                  });
                  try {
                    final owner = ref.read(careOwnerIdProvider);
                    if (owner == null) throw StateError('Inicia sesión.');
                    final repository = ref.read(
                      feedingHistoryRepositoryProvider,
                    );
                    final grams =
                        double.tryParse(_grams.text.replaceAll(',', '.')) ?? 0;
                    if (widget.schedule == null) {
                      await repository.addManual(
                        userId: owner,
                        pet: widget.pet,
                        grams: grams,
                        food: _food.text,
                      );
                    } else {
                      await repository
                          .markAsFed(
                            userId: owner,
                            pet: widget.pet,
                            scheduleId: widget.schedule!.id,
                            scheduledTime: widget.schedule!.time,
                            grams: grams,
                            food: _food.text,
                          )
                          .timeout(const Duration(seconds: 15));
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (mounted) {
                      setState(() {
                        _busy = false;
                        _error =
                            'No se confirmó la comida. Revisa tu conexión y consulta el historial antes de reintentar.';
                      });
                    }
                  }
                },
          child: const Text('Guardar comida'),
        ),
      ],
    ),
  );
}

class _PlanEditor extends StatefulWidget {
  const _PlanEditor({required this.plan});
  final CarePlan plan;
  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _grams, _weight, _meals, _food, _notes;
  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _grams = TextEditingController(text: gramsLabel(p.dailyGrams));
    _weight = TextEditingController(text: gramsLabel(p.weightKg));
    _meals = TextEditingController(text: '${p.mealsPerDay}');
    _food = TextEditingController(text: p.food);
    _notes = TextEditingController(text: p.notes);
  }

  @override
  void dispose() {
    for (final c in [_grams, _weight, _meals, _food, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _number(TextEditingController c, String label, double max) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (s) {
        final n = double.tryParse((s ?? '').replaceAll(',', '.'));
        return n == null || !n.isFinite || n < 0 || n > max
            ? 'Usa un valor entre 0 y $max.'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Plan y peso', textAlign: TextAlign.center),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _number(_weight, 'Peso registrado (kg)', 1000),
            _number(_grams, 'Cantidad diaria indicada (g)', 10000),
            TextFormField(
              controller: _meals,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Comidas por día (1 a 12)',
              ),
              validator: (s) {
                final n = int.tryParse(s ?? '');
                return n == null || n < 1 || n > 12
                    ? 'Indica de 1 a 12 comidas.'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _food,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Nombre del alimento',
              ),
            ),
            TextFormField(
              controller: _notes,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Indicaciones del plan',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              CarePlan(
                dailyGrams: double.parse(_grams.text.replaceAll(',', '.')),
                weightKg: double.parse(_weight.text.replaceAll(',', '.')),
                mealsPerDay: int.parse(_meals.text),
                food: _food.text,
                notes: _notes.text,
              ),
            );
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _MedicalEditor extends StatefulWidget {
  const _MedicalEditor({this.record});
  final MedicalRecord? record;
  @override
  State<_MedicalEditor> createState() => _MedicalEditorState();
}

class _MedicalEditorState extends State<_MedicalEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _notes;
  late String _kind;
  late DateTime _date;
  DateTime? _next;
  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _title = TextEditingController(text: r?.title ?? '');
    _notes = TextEditingController(text: r?.notes ?? '');
    _kind = r?.kind ?? 'Consulta';
    _date = r?.date ?? DateTime.now();
    _next = r?.nextDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool next) async {
    final date = await showDatePicker(
      context: context,
      initialDate: next ? _next ?? DateTime.now() : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() {
        if (next) {
          _next = date;
        } else {
          _date = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registro médico', textAlign: TextAlign.center),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (s) => (s?.trim().length ?? 0) < 2
                    ? 'Escribe un título de al menos 2 caracteres.'
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items:
                    [
                          'Consulta',
                          'Vacuna',
                          'Desparasitación',
                          'Tratamiento',
                          'Otro',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (s) => setState(() => _kind = s!),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _pick(false),
                child: Text('Fecha: ${careDate(_date)}'),
              ),
              OutlinedButton(
                onPressed: () => _pick(true),
                child: Text(
                  _next == null
                      ? 'Agregar próxima fecha'
                      : 'Próxima: ${careDate(_next!)}',
                ),
              ),
              if (_next != null)
                TextButton(
                  onPressed: () => setState(() => _next = null),
                  child: const Text('Quitar próxima fecha'),
                ),
              TextFormField(
                controller: _notes,
                maxLength: 1000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notas e indicaciones',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              MedicalRecord(
                id: widget.record?.id ?? '',
                title: _title.text,
                kind: _kind,
                date: _date,
                notes: _notes.text,
                nextDate: _next,
              ),
            );
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
