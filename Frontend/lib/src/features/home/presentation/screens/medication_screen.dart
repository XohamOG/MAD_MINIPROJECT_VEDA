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
                onPressed: () {},
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
