import 'dart:async';

import 'package:flutter/material.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class NotificationSimulatorScreen extends StatefulWidget {
  const NotificationSimulatorScreen({super.key});

  @override
  State<NotificationSimulatorScreen> createState() =>
      _NotificationSimulatorScreenState();
}

class _NotificationSimulatorScreenState
    extends State<NotificationSimulatorScreen> {
  static const List<_NotificationPreset> _presets = [
    _NotificationPreset(
      title: 'Appointment Reminder',
      message: 'You have a follow-up with Dr. Sharma today at 5:30 PM.',
      category: 'Appointments',
      icon: Icons.event_available_rounded,
    ),
    _NotificationPreset(
      title: 'Medicine Time',
      message: 'Take 1 tablet of Metformin now with water.',
      category: 'Medicines',
      icon: Icons.medication_rounded,
    ),
    _NotificationPreset(
      title: 'Medicine Refill Alert',
      message: 'Only 2 doses left of Amlodipine. Refill today.',
      category: 'Medicines',
      icon: Icons.local_pharmacy_rounded,
    ),
    _NotificationPreset(
      title: 'Lab Report Ready',
      message: 'Your blood test report is now available for review.',
      category: 'Reports',
      icon: Icons.description_rounded,
    ),
    _NotificationPreset(
      title: 'Hydration Reminder',
      message: 'It is time to drink a glass of water.',
      category: 'Wellness',
      icon: Icons.water_drop_rounded,
    ),
    _NotificationPreset(
      title: 'Vitals Check-In',
      message: 'Please log blood pressure and glucose readings.',
      category: 'Monitoring',
      icon: Icons.monitor_heart_rounded,
    ),
    _NotificationPreset(
      title: 'Walk Break',
      message: 'Take a 10-minute walk to stay active.',
      category: 'Wellness',
      icon: Icons.directions_walk_rounded,
    ),
    _NotificationPreset(
      title: 'Sleep Routine',
      message: 'Prepare for bed to keep your sleep schedule consistent.',
      category: 'Wellness',
      icon: Icons.bedtime_rounded,
    ),
  ];

  final List<Timer> _timers = <Timer>[];
  final List<_NotificationLog> _history = <_NotificationLog>[];

  late _NotificationPreset _selectedPreset;
  final TextEditingController _contextController = TextEditingController();
  int _delaySeconds = 0;

  @override
  void initState() {
    super.initState();
    _selectedPreset = _presets.first;
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const GradientHeader(
          title: 'Notification Simulator',
          subtitle: 'Preview reminder alerts for health workflows',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ActionCard(
                title: 'Simulate notification',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<_NotificationPreset>(
                      value: _selectedPreset,
                      items:
                          _presets
                              .map(
                                (preset) =>
                                    DropdownMenuItem<_NotificationPreset>(
                                      value: preset,
                                      child: Text(preset.title),
                                    ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedPreset = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Notification type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contextController,
                      decoration: const InputDecoration(
                        labelText: 'Additional context (optional)',
                        hintText:
                            'Example: Bring previous reports and insurance card.',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Delay: ${_delaySeconds}s',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _delaySeconds.toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '${_delaySeconds}s',
                      onChanged:
                          (value) =>
                              setState(() => _delaySeconds = value.round()),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _simulateSelectedNotification,
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: Text(
                          _delaySeconds == 0
                              ? 'Send Simulation Now'
                              : 'Schedule in ${_delaySeconds}s',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Recommended healthcare notifications',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ..._presets.map(
                (preset) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5F1),
                      child: Icon(preset.icon, color: const Color(0xFF1D7E68)),
                    ),
                    title: Text(preset.title),
                    subtitle: Text(
                      '${preset.message}\nCategory: ${preset.category}',
                    ),
                    isThreeLine: true,
                    trailing: OutlinedButton(
                      onPressed:
                          () =>
                              _deliverNotification(preset, customContext: null),
                      child: const Text('Send'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Simulation history',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _history.isEmpty
                            ? null
                            : () => setState(_history.clear),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              if (_history.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No notifications simulated yet.'),
                  ),
                )
              else
                ..._history.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(item.icon, color: const Color(0xFF1D7E68)),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.message}\n${_formatTime(item.sentAt)}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _simulateSelectedNotification() {
    final scheduledPreset = _selectedPreset;
    final contextText = _contextController.text.trim();
    final scheduledContext = contextText.isEmpty ? null : contextText;

    if (_delaySeconds == 0) {
      _deliverNotification(scheduledPreset, customContext: scheduledContext);
      return;
    }

    late final Timer timer;
    timer = Timer(Duration(seconds: _delaySeconds), () {
      _timers.remove(timer);
      if (!mounted) return;
      _deliverNotification(scheduledPreset, customContext: scheduledContext);
    });
    _timers.add(timer);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Simulation scheduled in ${_delaySeconds}s.'),
      ),
    );
  }

  void _deliverNotification(
    _NotificationPreset preset, {
    String? customContext,
  }) {
    final message =
        customContext == null || customContext.isEmpty
            ? preset.message
            : '${preset.message} ${customContext.trim()}';

    final now = DateTime.now();
    setState(
      () => _history.insert(
        0,
        _NotificationLog(
          title: preset.title,
          message: message,
          icon: preset.icon,
          sentAt: now,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(preset.icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${preset.title}\n$message',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return 'Sent at $hour:$minute:$second';
  }
}

class _NotificationPreset {
  const _NotificationPreset({
    required this.title,
    required this.message,
    required this.category,
    required this.icon,
  });

  final String title;
  final String message;
  final String category;
  final IconData icon;
}

class _NotificationLog {
  const _NotificationLog({
    required this.title,
    required this.message,
    required this.icon,
    required this.sentAt,
  });

  final String title;
  final String message;
  final IconData icon;
  final DateTime sentAt;
}
