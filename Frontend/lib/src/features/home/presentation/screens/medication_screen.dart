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

  Future<void> _openAddMedicationSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final notesController = TextEditingController();
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Medicine',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Medicine name'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Medicine name is required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: dosageController,
                        decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg)'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Dosage is required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: frequencyController,
                        decoration: const InputDecoration(labelText: 'Frequency (e.g. Twice daily)'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Frequency is required' : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reminder time'),
                        subtitle: Text(_formatTime(reminderTime)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: reminderTime,
                          );
                          if (selected != null) {
                            setSheetState(() => reminderTime = selected);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start date'),
                        subtitle: Text(_formatDate(startDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: startDate,
                          );
                          if (selected != null) {
                            setSheetState(() => startDate = selected);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('End date (optional)'),
                        subtitle: Text(endDate == null ? 'Not set' : _formatDate(endDate!)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (endDate != null)
                              IconButton(
                                onPressed: () => setSheetState(() => endDate = null),
                                icon: const Icon(Icons.clear),
                              ),
                            const Icon(Icons.event),
                          ],
                        ),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            firstDate: startDate,
                            lastDate: DateTime(2100),
                            initialDate: endDate ?? startDate,
                          );
                          if (selected != null) {
                            setSheetState(() => endDate = selected);
                          }
                        },
                      ),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Notes (optional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final token = context.read<AuthController>().token;
                            if (token == null || token.isEmpty) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please login again.')),
                              );
                              return;
                            }

                            final payload = <String, dynamic>{
                              'name': nameController.text.trim(),
                              'dosage': dosageController.text.trim(),
                              'frequency': frequencyController.text.trim(),
                              'reminder_time': '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}:00',
                              'start_date': _formatDate(startDate),
                              'notes': notesController.text.trim(),
                              'is_active': true,
                              if (endDate != null) 'end_date': _formatDate(endDate!),
                            };

                            final success = await context.read<HealthController>().addMedication(
                                  token: token,
                                  payload: payload,
                                );
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.of(sheetContext).pop(true);
                            } else {
                              final errorMessage = context.read<HealthController>().errorMessage ?? 'Failed to add medicine.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMessage)),
                              );
                            }
                          },
                          icon: context.watch<HealthController>().isSavingMedication
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            context.watch<HealthController>().isSavingMedication ? 'Saving...' : 'Save Medicine',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    notesController.dispose();

    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
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
                onPressed: health.isSavingMedication ? null : _openAddMedicationSheet,
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
