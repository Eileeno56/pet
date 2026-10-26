import 'package:flutter/material.dart';
import 'package:petreminder_user/models/feeding_schedule.dart';

class ScheduleDraft {
  const ScheduleDraft(
    this.time,
    this.label,
    this.foodType,
    this.notes,
    this.weekdays,
  );
  final String time, label, foodType, notes;
  final List<int> weekdays;
}

class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({this.schedule, super.key});
  final FeedingSchedule? schedule;
  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label, _food, _notes;
  late TimeOfDay _time;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _label = TextEditingController(text: s?.label ?? '');
    _food = TextEditingController(text: s?.foodType ?? 'Alimento');
    _notes = TextEditingController(text: s?.notes ?? '');
    _time = s == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: s.minutesSinceMidnight ~/ 60,
            minute: s.minutesSinceMidnight % 60,
          );
    _days = {
      ...?s?.weekdays,
      if (s == null) ...[1, 2, 3, 4, 5, 6, 7],
    };
  }

  @override
  void dispose() {
    _label.dispose();
    _food.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.schedule == null ? 'Nuevo horario' : 'Editar horario',
      textAlign: TextAlign.center,
    ),
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
                controller: _label,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Nombre del horario',
                  hintText: 'Desayuno, comida o cena',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text('Hora: ${_time.format(context)}'),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _time,
                    cancelText: 'Cancelar',
                    confirmText: 'Elegir',
                  );
                  if (time != null && mounted) setState(() => _time = time);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _food,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Tipo de alimento',
                  hintText: 'Croquetas, húmedo…',
                ),
                validator: (s) => (s?.trim().isEmpty ?? true)
                    ? 'Indica el tipo de alimento.'
                    : null,
              ),
              const SizedBox(height: 10),
              const Text('Repetir los días', textAlign: TextAlign.center),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(
                        const [
                          'Lun',
                          'Mar',
                          'Mié',
                          'Jue',
                          'Vie',
                          'Sáb',
                          'Dom',
                        ][d - 1],
                      ),
                      selected: _days.contains(d),
                      onSelected: (selected) => setState(() {
                        selected ? _days.add(d) : _days.remove(d);
                      }),
                    ),
                ],
              ),
              if (_days.isEmpty)
                Text(
                  'Selecciona al menos un día.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
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
        onPressed: _days.isEmpty
            ? null
            : () {
                if (!_form.currentState!.validate()) return;
                final days = _days.toList()..sort();
                Navigator.pop(
                  context,
                  ScheduleDraft(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                    _label.text.trim(),
                    _food.text.trim(),
                    _notes.text.trim(),
                    days,
                  ),
                );
              },
        child: const Text('Guardar'),
      ),
    ],
  );
}
