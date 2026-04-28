import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class NotificationSimulatorScreen extends StatefulWidget {
  const NotificationSimulatorScreen({super.key});

  @override
  State<NotificationSimulatorScreen> createState() => _NotificationSimulatorScreenState();
}

class _NotificationSimulatorScreenState extends State<NotificationSimulatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = context.read<AuthController>().token;
      if (token != null && token.isNotEmpty) {
        await context.read<HealthController>().loadDashboard(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final health = context.watch<HealthController>();
    final alerts = _buildAlerts(health);

    return SafeArea(
      child: Column(
        children: [
          const GradientHeader(
            title: 'Notifications',
            subtitle: 'Real appointment and medication reminders',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final token = auth.token;
                if (token != null && token.isNotEmpty) {
                  await context.read<HealthController>().loadDashboard(token);
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Active reminders',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${alerts.length} total'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (alerts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('No real notifications right now.'),
                      ),
                    )
                  else
                    ...alerts.map(
                      (alert) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: alert.color.withOpacity(0.12),
                            child: Icon(alert.icon, color: alert.color),
                          ),
                          title: Text(alert.title),
                          subtitle: Text(
                            alert.scheduledAt == null
                                ? alert.message
                                : '${alert.message}\n${_formatDateTime(alert.scheduledAt!)}',
                          ),
                          isThreeLine: alert.scheduledAt != null,
                          trailing: Chip(label: Text(alert.category)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_HealthAlert> _buildAlerts(HealthController health) {
    final alerts = <_HealthAlert>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final appointment in health.appointments) {
      final status = (appointment['status'] ?? 'scheduled').toString().toLowerCase();
      if (status != 'scheduled') continue;

      final scheduledAt = _parseAppointmentDateTime(
        appointment['appointment_date']?.toString(),
        appointment['appointment_time']?.toString(),
      );
      if (scheduledAt != null && scheduledAt.isBefore(today.subtract(const Duration(days: 1)))) {
        continue;
      }

      final doctorName = (appointment['doctor_name'] ?? 'Doctor').toString();
      final dateText = appointment['appointment_date']?.toString() ?? 'soon';
      final timeText = appointment['appointment_time']?.toString() ?? '--:--';
      alerts.add(
        _HealthAlert(
          title: 'Appointment reminder',
          message: '$doctorName on $dateText at $timeText',
          category: 'Appointment',
          icon: Icons.event_available_rounded,
          color: const Color(0xFF1E63C2),
          scheduledAt: scheduledAt,
        ),
      );
    }

    for (final medication in health.medications) {
      if ((medication['is_active'] ?? true) != true) continue;

      final startDate = _parseDate(medication['start_date']?.toString());
      final endDate = _parseDate(medication['end_date']?.toString());
      if (startDate != null && startDate.isAfter(today)) {
        continue;
      }
      if (endDate != null && endDate.isBefore(today)) {
        continue;
      }

      alerts.add(
        _HealthAlert(
          title: 'Medication reminder',
          message:
              '${medication['name'] ?? 'Medication'} - ${(medication['dosage'] ?? '').toString()} ${(medication['frequency'] ?? '').toString()}'.trim(),
          category: 'Medication',
          icon: Icons.medication_rounded,
          color: const Color(0xFF1D7E68),
          scheduledAt: _combineDateAndTime(today, medication['reminder_time']?.toString()),
        ),
      );
    }

    alerts.sort((left, right) {
      final leftTime = left.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime = right.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return leftTime.compareTo(rightTime);
    });

    return alerts;
  }

  DateTime? _parseAppointmentDateTime(String? dateText, String? timeText) {
    final date = _parseDate(dateText);
    if (date == null) return null;

    if (timeText == null || timeText.trim().isEmpty) return date;
    final parts = timeText.split(':');
    if (parts.length < 2) return date;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return date;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime? _combineDateAndTime(DateTime date, String? timeText) {
    if (timeText == null || timeText.trim().isEmpty) return date;
    final parts = timeText.split(':');
    if (parts.length < 2) return date;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return date;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime? _parseDate(String? dateText) {
    if (dateText == null || dateText.trim().isEmpty) return null;
    return DateTime.tryParse(dateText.trim());
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day-$month-$year  $hour:$minute';
  }
}

class _HealthAlert {
  const _HealthAlert({
    required this.title,
    required this.message,
    required this.category,
    required this.icon,
    required this.color,
    this.scheduledAt,
  });

  final String title;
  final String message;
  final String category;
  final IconData icon;
  final Color color;
  final DateTime? scheduledAt;
}
