import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _seatLimitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForDate();
    });
  }

  @override
  void dispose() {
    _seatLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final health = context.watch<HealthController>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Session expired. Please login again.')),
        ),
      );
    }

    final status = health.doctorDayStatus;
    final bool isFull = status?['is_full'] == true;
    final int seatLimit = (status?['seat_limit'] as int?) ?? (auth.user?.dailySeatLimit ?? 8);
    final int seatsBooked = (status?['seats_booked'] as int?) ?? 0;
    final int seatsRemaining = (status?['seats_remaining'] as int?) ?? 0;

    if (_seatLimitController.text.isEmpty) {
      _seatLimitController.text = seatLimit.toString();
    }

    return SafeArea(
      child: Column(
        children: [
          GradientHeader(
            title: 'Doctor Calendar',
            subtitle: 'Manage daily seats and patient bookings',
            trailing: IconButton(
              onPressed: () async {
                await context.read<AuthController>().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadForDate,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ActionCard(
                    title: 'Select date',
                    child: CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                          _seatLimitController.clear();
                        });
                        _loadForDate();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capacity - ${_isoDate(_selectedDate)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _seatLimitController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Daily seat limit',
                              prefixIcon: Icon(Icons.event_seat_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: Text('Booked: $seatsBooked')),
                              Expanded(child: Text('Remaining: $seatsRemaining')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: health.isUpdatingDoctorDayStatus
                                  ? null
                                  : () => _toggleDayStatus(
                                        currentIsFull: isFull,
                                        token: token,
                                      ),
                              icon: Icon(isFull ? Icons.check_circle_outline : Icons.block_rounded),
                              label: Text(isFull ? 'Mark day as available' : 'Mark day as full'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isFull ? 'This date is full. Patients cannot book now.' : 'This date is open for bookings.',
                            style: TextStyle(
                              color: isFull ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Patient appointments',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (health.doctorAppointments.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('No appointments for this date.'),
                      ),
                    )
                  else
                    ...health.doctorAppointments.map(
                      (item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_rounded),
                          title: Text((item['patient_name'] ?? 'Patient').toString()),
                          subtitle: Text(
                            '${item['appointment_time'] ?? ''}  |  ${item['reason'] ?? 'No reason'}',
                          ),
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

  Future<void> _toggleDayStatus({
    required bool currentIsFull,
    required String token,
  }) async {
    final parsedSeatLimit = int.tryParse(_seatLimitController.text.trim());
    if (parsedSeatLimit == null || parsedSeatLimit < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid seat limit.')),
      );
      return;
    }

    final ok = await context.read<HealthController>().updateDoctorDayStatus(
          token: token,
          date: _isoDate(_selectedDate),
          isFull: !currentIsFull,
          seatLimit: parsedSeatLimit,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (!currentIsFull ? 'Day marked full.' : 'Day marked available.')
            : context.read<HealthController>().errorMessage ?? 'Update failed.'),
      ),
    );
    if (ok) {
      await _loadForDate();
    }
  }

  Future<void> _loadForDate() async {
    final token = context.read<AuthController>().token;
    if (token == null || token.isEmpty) return;
    final isoDate = _isoDate(_selectedDate);
    await context.read<HealthController>().fetchDoctorDayStatus(token: token, date: isoDate);
    await context.read<HealthController>().fetchDoctorAppointments(token: token, date: isoDate);
    if (!mounted) return;
    final status = context.read<HealthController>().doctorDayStatus;
    final latestLimit = status?['seat_limit'];
    if (latestLimit is int) {
      _seatLimitController.text = latestLimit.toString();
    }
  }

  String _isoDate(DateTime date) => date.toIso8601String().split('T').first;
}
