import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final bpStatus = _evaluateBpStatus(user?.bpReading);
    final sugarStatus = _evaluateSugarStatus(user?.sugarLevel);
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
              Text(
                'Health status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _MetricStatusCard(
                title: 'Blood Pressure',
                value: user?.bpReading?.isNotEmpty == true ? user!.bpReading! : '--',
                status: bpStatus.status,
                hint: bpStatus.hint,
                color: bpStatus.color,
                icon: Icons.monitor_heart_rounded,
              ),
              const SizedBox(height: 8),
              _MetricStatusCard(
                title: 'Sugar Level',
                value: user?.sugarLevel?.isNotEmpty == true ? '${user!.sugarLevel} mg/dL' : '--',
                status: sugarStatus.status,
                hint: sugarStatus.hint,
                color: sugarStatus.color,
                icon: Icons.bloodtype_rounded,
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: 'Vitals trend',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Based on the latest profile readings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 220,
                      child: CustomPaint(
                        painter: _VitalsTrendPainter(chartData.points),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: chartData.points
                                .map(
                                  (point) => Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          point.displayValue,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          point.label,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _MetricStatus _evaluateBpStatus(String? reading) {
    if (reading == null || reading.trim().isEmpty) {
      return const _MetricStatus(
        status: 'Unknown',
        hint: 'Add BP in profile (example: 120/80).',
        color: Color(0xFF616161),
      );
    }

    final parts = reading.trim().split('/');
    if (parts.length != 2) {
      return const _MetricStatus(
        status: 'Unknown',
        hint: 'BP format should be systolic/diastolic.',
        color: Color(0xFF616161),
      );
    }

    final systolic = int.tryParse(parts[0].trim());
    final diastolic = int.tryParse(parts[1].trim());
    if (systolic == null || diastolic == null) {
      return const _MetricStatus(
        status: 'Unknown',
        hint: 'BP format should be systolic/diastolic.',
        color: Color(0xFF616161),
      );
    }

    if (systolic < 90 || diastolic < 60) {
      return const _MetricStatus(
        status: 'Low',
        hint: 'Below normal range (about 90/60 to 120/80).',
        color: Color(0xFF1565C0),
      );
    }
    if (systolic > 130 || diastolic > 85) {
      return const _MetricStatus(
        status: 'High',
        hint: 'Above normal range (about 90/60 to 120/80).',
        color: Color(0xFFC62828),
      );
    }
    return const _MetricStatus(
      status: 'Normal',
      hint: 'Within normal range (about 90/60 to 120/80).',
      color: Color(0xFF2E7D32),
    );
  }

  _MetricStatus _evaluateSugarStatus(String? sugar) {
    if (sugar == null || sugar.trim().isEmpty) {
      return const _MetricStatus(
        status: 'Unknown',
        hint: 'Add sugar value in profile (mg/dL).',
        color: Color(0xFF616161),
      );
    }

    final cleaned = sugar.trim().replaceAll(RegExp('[^0-9.]'), '');
    final value = double.tryParse(cleaned);
    if (value == null) {
      return const _MetricStatus(
        status: 'Unknown',
        hint: 'Sugar value should be numeric (mg/dL).',
        color: Color(0xFF616161),
      );
    }

    if (value < 70) {
      return const _MetricStatus(
        status: 'Low',
        hint: 'Below normal range (about 70 to 140 mg/dL).',
        color: Color(0xFF1565C0),
      );
    }
    if (value > 140) {
      return const _MetricStatus(
        status: 'High',
        hint: 'Above normal range (about 70 to 140 mg/dL).',
        color: Color(0xFFC62828),
      );
    }
    return const _MetricStatus(
      status: 'Normal',
      hint: 'Within normal range (about 70 to 140 mg/dL).',
      color: Color(0xFF2E7D32),
    );
  }
}

class _MetricStatus {
  const _MetricStatus({
    required this.status,
    required this.hint,
    required this.color,
  });

  final String status;
  final String hint;
  final Color color;
}

class _MetricStatusCard extends StatelessWidget {
  const _MetricStatusCard({
    required this.title,
    required this.value,
    required this.status,
    required this.hint,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String status;
  final String hint;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Current: $value'),
                  const SizedBox(height: 3),
                  Text(
                    '$status  |  $hint',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
