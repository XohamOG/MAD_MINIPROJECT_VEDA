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
    final chartData = _VitalsChartData.fromUser(user);
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
}

class _VitalsChartData {
  _VitalsChartData(this.points);

  final List<_VitalsPoint> points;

  factory _VitalsChartData.fromUser(user) {
    final bp = _readSystolic(user?.bpReading);
    final sugar = _readNumber(user?.sugarLevel);
    final heartRate = _readNumber(user?.heartRate);
    final weight = _readNumber(user?.weight);

    return _VitalsChartData([
      _VitalsPoint(label: 'BP', displayValue: bp == null ? '--' : '${bp.toStringAsFixed(0)} mmHg', normalizedValue: _normalize(bp, 80, 180)),
      _VitalsPoint(label: 'Sugar', displayValue: sugar == null ? '--' : '${sugar.toStringAsFixed(0)} mg/dL', normalizedValue: _normalize(sugar, 70, 250)),
      _VitalsPoint(label: 'HR', displayValue: heartRate == null ? '--' : '${heartRate.toStringAsFixed(0)} bpm', normalizedValue: _normalize(heartRate, 40, 160)),
      _VitalsPoint(label: 'Weight', displayValue: weight == null ? '--' : '${weight.toStringAsFixed(0)} kg', normalizedValue: _normalize(weight, 30, 150)),
    ]);
  }
}

class _VitalsPoint {
  const _VitalsPoint({
    required this.label,
    required this.displayValue,
    required this.normalizedValue,
  });

  final String label;
  final String displayValue;
  final double? normalizedValue;
}

class _VitalsTrendPainter extends CustomPainter {
  _VitalsTrendPainter(this.points);

  final List<_VitalsPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 16.0;
    const bottomPad = 36.0;
    const leftPad = 12.0;
    const rightPad = 12.0;

    final availableWidth = size.width - leftPad - rightPad;
    final availableHeight = size.height - topPad - bottomPad;
    final segmentWidth = points.length > 1 ? availableWidth / (points.length - 1) : availableWidth;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final dy = topPad + (availableHeight / 3) * index;
      canvas.drawLine(Offset(leftPad, dy), Offset(size.width - rightPad, dy), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2F78DD)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF2F78DD).withOpacity(0.22), const Color(0xFF2F78DD).withOpacity(0.02)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(leftPad, topPad, availableWidth, availableHeight));

    final validPoints = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (point.normalizedValue == null) continue;
      final dx = leftPad + segmentWidth * index;
      final dy = topPad + availableHeight * (1 - point.normalizedValue!.clamp(0.0, 1.0));
      validPoints.add(Offset(dx, dy));
    }

    if (validPoints.length >= 2) {
      final areaPath = Path()..moveTo(validPoints.first.dx, size.height - bottomPad);
      for (final point in validPoints) {
        areaPath.lineTo(point.dx, point.dy);
      }
      areaPath.lineTo(validPoints.last.dx, size.height - bottomPad);
      areaPath.close();
      canvas.drawPath(areaPath, fillPaint);

      final linePath = Path()..moveTo(validPoints.first.dx, validPoints.first.dy);
      for (final point in validPoints.skip(1)) {
        linePath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    for (final point in validPoints) {
      canvas.drawCircle(point, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3.5, Paint()..color = const Color(0xFF2F78DD));
    }
  }

  @override
  bool shouldRepaint(covariant _VitalsTrendPainter oldDelegate) => oldDelegate.points != points;
}

double? _readNumber(String? value) {
  if (value == null || value.isEmpty) return null;
  final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(value);
  return match == null ? null : double.tryParse(match.group(1)!);
}

double? _readSystolic(String? value) {
  if (value == null || value.isEmpty) return null;
  final match = RegExp(r'([0-9]+)').firstMatch(value);
  return match == null ? null : double.tryParse(match.group(1)!);
}

double _normalize(double? value, double min, double max) {
  if (value == null) return 0.5;
  final clamped = math.min(math.max(value, min), max);
  return (clamped - min) / (max - min);
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
