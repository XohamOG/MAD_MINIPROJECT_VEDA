import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    required this.onOpenTab,
    required this.onOpenMedication,
    required this.onOpenDigitalPrescription,
    required this.onOpenFindDoctor,
    required this.onOpenAddReport,
    required this.onOpenHealthDashboard,
    required this.onOpenNotificationSimulator,
    required this.onOpenSensorSimulation,
    super.key,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenMedication;
  final VoidCallback onOpenDigitalPrescription;
  final VoidCallback onOpenFindDoctor;
  final VoidCallback onOpenAddReport;
  final VoidCallback onOpenHealthDashboard;
  final VoidCallback onOpenNotificationSimulator;
  final VoidCallback onOpenSensorSimulation;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final health = context.watch<HealthController>();
    final token = auth.token;

    return SafeArea(
      child: Column(
        children: [
          GradientHeader(
            title: 'How are you?',
            subtitle:
                auth.user?.fullName.isNotEmpty == true
                    ? 'Welcome, ${auth.user!.fullName}'
                    : 'Welcome to Ashray',
            trailing: IconButton(
              onPressed: () async {
                await context.read<AuthController>().logout();
                if (!context.mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (token != null && token.isNotEmpty) {
                  await health.loadDashboard(token);
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  ActionCard(
                    title: 'Medication Reminder',
                    child: _MedicationCard(token: token),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      ServiceTile(
                        label: 'Medications',
                        icon: Icons.medication_rounded,
                        onTap: onOpenMedication,
                      ),
                      ServiceTile(
                        label: 'Digital Prescription',
                        icon: Icons.document_scanner_rounded,
                        onTap: onOpenDigitalPrescription,
                      ),
                      ServiceTile(
                        label: 'Find Doctor',
                        icon: Icons.local_hospital_rounded,
                        onTap: onOpenFindDoctor,
                      ),
                      ServiceTile(
                        label: 'Add Report',
                        icon: Icons.upload_file_rounded,
                        onTap: onOpenAddReport,
                      ),
                      ServiceTile(
                        label: 'Schedule',
                        icon: Icons.calendar_month_rounded,
                        onTap: () => onOpenTab(1),
                      ),
                      ServiceTile(
                        label: 'Health Dashboard',
                        icon: Icons.monitor_heart_rounded,
                        onTap: onOpenHealthDashboard,
                      ),
                      ServiceTile(
                        label: 'Notifications',
                        icon: Icons.notifications_active_rounded,
                        onTap: onOpenNotificationSimulator,
                      ),
                      ServiceTile(
                        label: 'Sensor Lab',
                        icon: Icons.sensors_rounded,
                        onTap: onOpenSensorSimulation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ServiceTile(
                    label: 'SOS',
                    icon: Icons.sos_rounded,
                    onTap: () => onOpenTab(3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthController>();

    if (health.isLoadingMedications) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final meds = health.medications;
    if (meds.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No medications yet.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              if (token != null && token!.isNotEmpty) {
                await context.read<HealthController>().fetchMedications(token!);
              }
            },
            child: const Text('Refresh'),
          ),
        ],
      );
    }

    final med = meds.first;
    final medId = med['id'] as int? ?? 0;
    final taken = health.isMedicationTakenToday(medId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${med['name'] ?? 'Medicine'} - ${med['dosage'] ?? ''}'),
        const SizedBox(height: 6),
        Text('Reminder: ${med['reminder_time'] ?? '--:--'}'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed:
              () => context.read<HealthController>().markTakenToday(medId),
          child: Text(taken ? 'Marked as Taken' : 'Mark as Taken'),
        ),
      ],
    );
  }
}
