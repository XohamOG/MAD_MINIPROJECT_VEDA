import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final Map<int, bool> _reminderEnabled = <int, bool>{};

  Future<void> _addMedication(BuildContext context) async {
    final auth = context.read<AuthController>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;

    final draft = await showDialog<_MedicationDraft>(
      context: context,
      builder: (context) => const _AddMedicationDialog(),
    );
    if (draft == null) return;

    final ok = await context.read<HealthController>().addMedication(
          token: token,
          payload: {
            'name': draft.name,
            'dosage': draft.dosage,
            'frequency': draft.frequency,
            'reminder_time': draft.reminderTime,
            'start_date': draft.startDate,
            if (draft.endDate != null) 'end_date': draft.endDate,
            if (draft.notes.isNotEmpty) 'notes': draft.notes,
            'is_active': true,
          },
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Medication added.' : context.read<HealthController>().errorMessage ?? 'Failed')),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthController>().token;
      if (token != null && token.isNotEmpty) {
        context.read<HealthController>().fetchMedications(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthController>();
    final meds = health.medications;

    return Column(
      children: [
        const GradientHeader(
          title: 'Medications',
          subtitle: 'Track doses and reminders',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (health.isLoadingMedications)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (meds.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No medications available.'),
                  ),
                )
              else
                ...meds.map((med) {
                  final id = med['id'] as int? ?? 0;
                  final reminderOn = _reminderEnabled[id] ?? true;
                  final taken = health.isMedicationTakenToday(id);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (med['name'] ?? 'Medication').toString(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('Dosage: ${(med['dosage'] ?? '')}'),
                          Text('Frequency: ${(med['frequency'] ?? '')}'),
                          Text('Reminder: ${(med['reminder_time'] ?? '--:--')}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => context.read<HealthController>().markTakenToday(id),
                                  child: Text(taken ? 'Taken today' : 'Mark as Taken'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Row(
                                children: [
                                  const Text('Reminder'),
                                  Switch(
                                    value: reminderOn,
                                    onChanged: (value) => setState(() => _reminderEnabled[id] = value),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _addMedication(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Medicine'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicationDraft {
  const _MedicationDraft({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTime,
    required this.startDate,
    required this.notes,
    this.endDate,
  });

  final String name;
  final String dosage;
  final String frequency;
  final String reminderTime;
  final String startDate;
  final String notes;
  final String? endDate;
}

class _AddMedicationDialog extends StatefulWidget {
  const _AddMedicationDialog();

  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay _reminderTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime date) => date.toIso8601String().split('T').first;
    String formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medication name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _frequencyController,
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('Start date: ${formatDate(_startDate)}')),
                IconButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  icon: const Icon(Icons.date_range),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reminder time: ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
                    if (picked != null) setState(() => _reminderTime = picked);
                  },
                  icon: const Icon(Icons.access_time),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('End date: ${_endDate == null ? 'Not set' : formatDate(_endDate!)}')),
                IconButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _startDate,
                      firstDate: _startDate,
                      lastDate: DateTime(2035),
                    );
                    setState(() => _endDate = picked);
                  },
                  icon: const Icon(Icons.event_busy_outlined),
                ),
                if (_endDate != null)
                  IconButton(
                    onPressed: () => setState(() => _endDate = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final dosage = _dosageController.text.trim();
            final frequency = _frequencyController.text.trim();
            if (name.isEmpty || dosage.isEmpty || frequency.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill medication name, dosage, and frequency.')),
              );
              return;
            }

            Navigator.pop(
              context,
              _MedicationDraft(
                name: name,
                dosage: dosage,
                frequency: frequency,
                reminderTime: formatTime(_reminderTime),
                startDate: formatDate(_startDate),
                endDate: _endDate == null ? null : formatDate(_endDate!),
                notes: _notesController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
