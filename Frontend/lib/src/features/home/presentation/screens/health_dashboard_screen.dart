import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return Column(
      children: [
        const GradientHeader(
          title: 'Health Dashboard',
          subtitle: 'Track your key vitals daily',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  _MetricCard(title: 'BP', value: user?.bpReading?.isNotEmpty == true ? user!.bpReading! : '--'),
                  _MetricCard(
                    title: 'Sugar',
                    value: user?.sugarLevel?.isNotEmpty == true ? '${user!.sugarLevel} mg/dL' : '--',
                  ),
                  _MetricCard(
                    title: 'Heart Rate',
                    value: user?.heartRate?.isNotEmpty == true ? '${user!.heartRate} bpm' : '--',
                  ),
                  _MetricCard(title: 'Weight', value: user?.weight?.isNotEmpty == true ? '${user!.weight} kg' : '--'),
                ],
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: 'Weekly trend',
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Chart Placeholder',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2C6E5E)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
