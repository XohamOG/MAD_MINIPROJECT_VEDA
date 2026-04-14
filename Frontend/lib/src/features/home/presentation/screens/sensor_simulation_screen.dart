import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class SensorSimulationScreen extends StatefulWidget {
  const SensorSimulationScreen({super.key});

  @override
  State<SensorSimulationScreen> createState() => _SensorSimulationScreenState();
}

class _SensorSimulationScreenState extends State<SensorSimulationScreen> {
  static const int _maxAlertHistoryItems = 40;

  Timer? _coachTimer;

  double _movementScore = 25;
  int _stepCount = 1200;
  int _sedentaryMinutes = 0;
  int _sedentaryThreshold = 45;
  bool _coachRunning = false;
  bool _sedentaryAlertSent = false;

  double _impactG = 1.8;
  int _stillnessSeconds = 3;
  String _fallRiskLabel = 'Low';

  int _minutesSinceWater = 90;
  int _glassesToday = 3;
  final int _dailyHydrationGoal = 8;
  bool _hotWeatherMode = false;

  final List<_SensorAlertLog> _alertHistory = <_SensorAlertLog>[];

  @override
  void dispose() {
    _stopCoach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activityLabel = _activityLabel(_movementScore);
    final hydrationInterval = _recommendedHydrationInterval();
    final hydrationDue = _minutesSinceWater >= hydrationInterval;

    return Column(
      children: [
        const GradientHeader(
          title: 'Sensor Simulation Lab',
          subtitle: 'Activity coach, fall-risk alerts, hydration nudges',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ActionCard(
                title: '1) Activity and Sedentary Coach',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      'Movement level',
                      '$activityLabel (${_movementScore.toStringAsFixed(0)}/100)',
                    ),
                    _infoRow('Steps today', '$_stepCount steps'),
                    _infoRow('Sedentary time', '$_sedentaryMinutes min'),
                    _infoRow(
                      'Inactivity threshold',
                      '$_sedentaryThreshold min',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Movement simulation',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _movementScore,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _movementScore.toStringAsFixed(0),
                      onChanged:
                          (value) => setState(() => _movementScore = value),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inactivity threshold (minutes)',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _sedentaryThreshold.toDouble(),
                      min: 15,
                      max: 90,
                      divisions: 15,
                      label: '$_sedentaryThreshold',
                      onChanged:
                          (value) => setState(
                            () => _sedentaryThreshold = value.round(),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleCoach,
                          icon: Icon(
                            _coachRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            _coachRunning ? 'Stop Coach' : 'Start Coach',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _runCoachCycle,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Run One Cycle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: '2) Fall Risk Alert',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Current risk', _fallRiskLabel),
                    const SizedBox(height: 8),
                    Text(
                      'Impact simulation (g-force)',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _impactG,
                      min: 1,
                      max: 6,
                      divisions: 50,
                      label: _impactG.toStringAsFixed(1),
                      onChanged: (value) => setState(() => _impactG = value),
                    ),
                    Text(
                      'Post-impact stillness (seconds)',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _stillnessSeconds.toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '$_stillnessSeconds',
                      onChanged:
                          (value) =>
                              setState(() => _stillnessSeconds = value.round()),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: _evaluateFallRisk,
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: const Text('Evaluate Fall Risk'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: '3) Hydration Nudges',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Minutes since water', '$_minutesSinceWater min'),
                    _infoRow(
                      'Glasses today',
                      '$_glassesToday / $_dailyHydrationGoal',
                    ),
                    _infoRow(
                      'Recommended nudge every',
                      '$hydrationInterval min',
                    ),
                    _infoRow(
                      'Nudge status',
                      hydrationDue ? 'Due now' : 'On track',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minutes since last water intake',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _minutesSinceWater.toDouble(),
                      min: 0,
                      max: 300,
                      divisions: 60,
                      label: '$_minutesSinceWater',
                      onChanged:
                          (value) => setState(
                            () => _minutesSinceWater = value.round(),
                          ),
                    ),
                    Text(
                      'Glasses consumed today',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _glassesToday.toDouble(),
                      min: 0,
                      max: 12,
                      divisions: 12,
                      label: '$_glassesToday',
                      onChanged:
                          (value) =>
                              setState(() => _glassesToday = value.round()),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hotWeatherMode,
                      onChanged:
                          (value) => setState(() => _hotWeatherMode = value),
                      title: const Text('Hot weather mode'),
                      subtitle: const Text('Nudges become more frequent'),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _checkHydration,
                          icon: const Icon(Icons.water_drop_rounded),
                          label: const Text('Check Hydration Nudge'),
                        ),
                        OutlinedButton(
                          onPressed: _markWaterIntake,
                          child: const Text('Mark Water Intake'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Alert history',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _alertHistory.isEmpty
                            ? null
                            : () => setState(_alertHistory.clear),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              if (_alertHistory.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'No alerts yet. Start simulation to generate events.',
                    ),
                  ),
                )
              else
                ..._alertHistory.map(
                  (alert) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5F1),
                        child: Icon(alert.icon, color: const Color(0xFF1D7E68)),
                      ),
                      title: Text(alert.title),
                      subtitle: Text(
                        '${alert.message}\n${_formatTime(alert.createdAt)}',
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D7E68),
            ),
          ),
        ],
      ),
    );
  }

  String _activityLabel(double score) {
    if (score >= 70) {
      return 'Active';
    }
    if (score >= 35) {
      return 'Moderate';
    }
    return 'Low';
  }

  void _toggleCoach() {
    if (_coachRunning) {
      _stopCoach();
      return;
    }

    _coachTimer?.cancel();
    _coachTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _runCoachCycle();
    });

    setState(() => _coachRunning = true);
  }

  void _runCoachCycle() {
    final score = _movementScore;
    final simulatedStepIncrease = math.max(0, (score / 8).round());
    var shouldRaiseSedentaryAlert = false;
    var currentSedentaryMinutes = _sedentaryMinutes;

    setState(() {
      _stepCount += simulatedStepIncrease;

      if (score < 35) {
        _sedentaryMinutes += 5;
      } else {
        _sedentaryMinutes = math.max(0, _sedentaryMinutes - 8);
        _sedentaryAlertSent = false;
      }

      if (_sedentaryMinutes >= _sedentaryThreshold && !_sedentaryAlertSent) {
        _sedentaryAlertSent = true;
        shouldRaiseSedentaryAlert = true;
        currentSedentaryMinutes = _sedentaryMinutes;
      }
    });

    if (shouldRaiseSedentaryAlert) {
      _raiseAlert(
        title: 'Sedentary Coach',
        message:
            'You have been inactive for $currentSedentaryMinutes minutes. Time for a short walk.',
        icon: Icons.directions_walk_rounded,
      );
    }
  }

  void _stopCoach() {
    _coachTimer?.cancel();
    _coachTimer = null;
    if (_coachRunning) {
      setState(() => _coachRunning = false);
    }
  }

  void _evaluateFallRisk() {
    String nextRisk = 'Low';
    String message = 'Normal movement pattern.';

    if (_impactG >= 3.8 && _stillnessSeconds >= 10) {
      nextRisk = 'High';
      message =
          'Potential fall detected. Please confirm safety or trigger SOS.';
    } else if (_impactG >= 2.8 && _stillnessSeconds >= 6) {
      nextRisk = 'Medium';
      message =
          'Unusual impact and stillness pattern detected. Check user status.';
    }

    setState(() => _fallRiskLabel = nextRisk);

    if (nextRisk != 'Low') {
      _raiseAlert(
        title: 'Fall Risk $nextRisk',
        message: message,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Fall risk is low for current simulation values.'),
      ),
    );
  }

  int _recommendedHydrationInterval() {
    var minutes = 120;

    if (_movementScore >= 60) {
      minutes -= 20;
    }
    if (_hotWeatherMode) {
      minutes -= 20;
    }

    return math.max(45, minutes);
  }

  void _checkHydration() {
    final interval = _recommendedHydrationInterval();
    if (_minutesSinceWater >= interval) {
      _raiseAlert(
        title: 'Hydration Nudge',
        message:
            'It has been $_minutesSinceWater minutes since your last glass of water.',
        icon: Icons.water_drop_rounded,
      );
      return;
    }

    final remaining = interval - _minutesSinceWater;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Hydration is on track. Next nudge in about $remaining minutes.',
        ),
      ),
    );
  }

  void _markWaterIntake() {
    setState(() {
      _minutesSinceWater = 0;
      _glassesToday = math.min(_dailyHydrationGoal + 4, _glassesToday + 1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Water intake recorded.'),
      ),
    );
  }

  void _raiseAlert({
    required String title,
    required String message,
    required IconData icon,
  }) {
    if (!mounted) return;

    final now = DateTime.now();

    setState(() {
      _alertHistory.insert(
        0,
        _SensorAlertLog(
          title: title,
          message: message,
          icon: icon,
          createdAt: now,
        ),
      );
      if (_alertHistory.length > _maxAlertHistoryItems) {
        _alertHistory.removeRange(_maxAlertHistoryItems, _alertHistory.length);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$title\n$message',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return 'Logged at $hour:$minute:$second';
  }
}

class _SensorAlertLog {
  const _SensorAlertLog({
    required this.title,
    required this.message,
    required this.icon,
    required this.createdAt,
  });

  final String title;
  final String message;
  final IconData icon;
  final DateTime createdAt;
}
