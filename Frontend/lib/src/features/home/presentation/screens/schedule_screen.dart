import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _addAppointment(BuildContext context) async {
    final auth = context.read<AuthController>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;

    final result = await showDialog<_AppointmentDraft>(
      context: context,
      builder: (context) => const _AddAppointmentDialog(),
    );

    if (result == null) return;
    final ok = await context.read<HealthController>().addAppointment(
          token: token,
          payload: {
            'doctor_name': result.doctorName,
            'specialty': result.specialty,
            'hospital_name': result.hospitalName,
            'appointment_date': result.date,
            'appointment_time': result.time,
            'reason': result.reason,
          },
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Appointment added.' : context.read<HealthController>().errorMessage ?? 'Failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<HealthController>().appointments;
    return SafeArea(
      child: Column(
        children: [
          const GradientHeader(
            title: 'Schedule',
            subtitle: 'Manage appointments',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ActionCard(
                  title: 'Calendar view',
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    onDateChanged: (date) => setState(() => _selectedDate = date),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _addAppointment(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Appointment'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upcoming appointments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (appointments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No upcoming appointments.'),
                    ),
                  )
                else
                  ...appointments.map(
                    (item) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available_rounded),
                        title: Text((item['doctor_name'] ?? 'Doctor').toString()),
                        subtitle: Text(
                          '${item['appointment_date'] ?? ''}  ${item['appointment_time'] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text((item['status'] ?? 'scheduled').toString()),
                            IconButton(
                              onPressed: () => _deleteAppointment(item['id'] as int?),
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppointment(int? id) async {
    if (id == null) return;
    final token = context.read<AuthController>().token;
    if (token == null || token.isEmpty) return;
    final ok = await context.read<HealthController>().deleteAppointment(token: token, id: id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Appointment deleted.' : context.read<HealthController>().errorMessage ?? 'Delete failed'),
      ),
    );
  }
}

class _AppointmentDraft {
  const _AppointmentDraft({
    required this.doctorName,
    required this.specialty,
    required this.hospitalName,
    required this.date,
    required this.time,
    required this.reason,
  });

  final String doctorName;
  final String specialty;
  final String hospitalName;
  final String date;
  final String time;
  final String reason;
}

class _AddAppointmentDialog extends StatefulWidget {
  const _AddAppointmentDialog();

  @override
  State<_AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<_AddAppointmentDialog> {
  final _doctorController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() {
    _doctorController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add appointment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _doctorController, decoration: const InputDecoration(labelText: 'Doctor name')),
            const SizedBox(height: 8),
            TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: 'Specialty')),
            const SizedBox(height: 8),
            TextField(controller: _hospitalController, decoration: const InputDecoration(labelText: 'Hospital')),
            const SizedBox(height: 8),
            TextField(controller: _reasonController, decoration: const InputDecoration(labelText: 'Reason')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Date: ${_date.toIso8601String().split('T').first}')),
                IconButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  icon: const Icon(Icons.date_range),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Time: ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                ),
                IconButton(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _AppointmentDraft(
                doctorName: _doctorController.text.trim(),
                specialty: _specialtyController.text.trim(),
                hospitalName: _hospitalController.text.trim(),
                date: _date.toIso8601String().split('T').first,
                time: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00',
                reason: _reasonController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
