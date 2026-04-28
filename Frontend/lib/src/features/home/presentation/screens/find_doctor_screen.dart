import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedArea = 'All';
  DateTime _selectedDate = DateTime.now();

  final _categoryFilters = const ['All', 'Cardiologist', 'Diabetologist', 'General Physician'];
  final _areaFilters = const ['All', 'Chembur', 'Kurla', 'Ghatkopar'];

  // Hardcoded doctors from Chembur, Mumbai.
  final List<Map<String, dynamic>> _seedDoctors = const [
    {
      'seed_email': 'ananya.shah@veda.doctor',
      'full_name': 'Dr. Ananya Shah',
      'doctor_category': 'Cardiologist',
      'doctor_area': 'Chembur',
      'doctor_city': 'Mumbai',
      'rating': '4.9',
      'distance': '1.8 km',
      'daily_seat_limit': 6,
    },
    {
      'seed_email': 'rohit.kulkarni@veda.doctor',
      'full_name': 'Dr. Rohit Kulkarni',
      'doctor_category': 'Diabetologist',
      'doctor_area': 'Chembur',
      'doctor_city': 'Mumbai',
      'rating': '4.8',
      'distance': '2.1 km',
      'daily_seat_limit': 8,
    },
    {
      'seed_email': 'neha.patil@veda.doctor',
      'full_name': 'Dr. Neha Patil',
      'doctor_category': 'General Physician',
      'doctor_area': 'Chembur',
      'doctor_city': 'Mumbai',
      'rating': '4.7',
      'distance': '1.5 km',
      'daily_seat_limit': 10,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthController>();
    final query = _searchController.text.trim().toLowerCase();

    final mergedDoctors = _seedDoctors.map((seedDoctor) {
      final seedEmail = (seedDoctor['seed_email'] ?? '').toString();
      final liveDoctor = health.doctors.cast<Map<String, dynamic>?>().firstWhere(
            (doctor) =>
                (doctor?['email'] ?? '').toString().toLowerCase() ==
                seedEmail.toLowerCase(),
            orElse: () => null,
          );
      return {
        ...seedDoctor,
        if (liveDoctor != null) ...liveDoctor,
      };
    }).toList();

    final visible = mergedDoctors.where((doc) {
      final category = (doc['doctor_category'] ?? '').toString().toLowerCase();
      final name = (doc['full_name'] ?? '').toString().toLowerCase();
      final area = (doc['doctor_area'] ?? '').toString().toLowerCase();

      final categoryOk = _selectedCategory == 'All' || category == _selectedCategory.toLowerCase();
      final areaOk = _selectedArea == 'All' || area == _selectedArea.toLowerCase();
      final queryOk = query.isEmpty || name.contains(query) || category.contains(query) || area.contains(query);

      return categoryOk && areaOk && queryOk;
    }).toList();

    return Column(
      children: [
        const GradientHeader(
          title: 'Find Doctor',
          subtitle: 'Filter by area and category in Chembur, Mumbai',
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDoctors,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search doctors by name/category/area',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Availability: ${_isoDate(_selectedDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime(2035),
                            );
                            if (picked == null) return;
                            setState(() => _selectedDate = picked);
                            await _loadDoctors();
                          },
                          icon: const Icon(Icons.calendar_month_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _areaFilters
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item),
                              selected: _selectedArea == item,
                              onSelected: (_) => setState(() => _selectedArea = item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categoryFilters
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item),
                              selected: _selectedCategory == item,
                              onSelected: (_) => setState(() => _selectedCategory = item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (health.isLoadingDoctors)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (visible.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No doctors found for selected filters.'),
                    ),
                  )
                else
                  ...visible.map(
                    (doc) {
                      final doctorId = doc['id'] as int?;
                      final seatsRemaining = doc['seats_remaining'] as int?;
                      final bool isFull = doc['is_full_for_date'] == true || (seatsRemaining != null && seatsRemaining <= 0);
                      final category = (doc['doctor_category'] ?? '').toString();
                      final area = (doc['doctor_area'] ?? '').toString();
                      final city = (doc['doctor_city'] ?? '').toString();
                      final doctorName = (doc['full_name'] ?? '').toString();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctorName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text('$category • ⭐ ${doc['rating']} • ${doc['distance']}'),
                              const SizedBox(height: 4),
                              Text('$area, $city'),
                              const SizedBox(height: 6),
                              Text(
                                isFull
                                    ? 'Full for selected date'
                                    : '${seatsRemaining ?? doc['daily_seat_limit'] ?? '--'} seats available',
                                style: TextStyle(
                                  color: isFull ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.call_rounded),
                                      label: const Text('Call'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isFull || doctorId == null
                                          ? null
                                          : () => _bookDoctor(
                                                doctorId: doctorId,
                                                doctorName: doctorName,
                                                category: category,
                                              ),
                                      icon: const Icon(Icons.calendar_today_rounded),
                                      label: const Text('Book'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _bookDoctor({
    required int doctorId,
    required String doctorName,
    required String category,
  }) async {
    final token = context.read<AuthController>().token;
    if (token == null || token.isEmpty) {
      return;
    }

    final draft = await showDialog<_DoctorBookingDraft>(
      context: context,
      builder: (_) => _DoctorBookingDialog(
        doctorName: doctorName,
        category: category,
        initialDate: _selectedDate,
      ),
    );

    if (draft == null) return;

    final ok = await context.read<HealthController>().addAppointment(
          token: token,
          payload: {
            'doctor_id': doctorId,
            'appointment_date': draft.date,
            'appointment_time': draft.time,
            'reason': draft.reason,
          },
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Appointment booked.'
              : context.read<HealthController>().errorMessage ?? 'Booking failed.',
        ),
      ),
    );

    if (ok) {
      await context.read<HealthController>().fetchAppointments(token);
      await _loadDoctors();
    }
  }

  Future<void> _loadDoctors() async {
    final token = context.read<AuthController>().token;
    if (token == null || token.isEmpty) return;
    await context.read<HealthController>().fetchDoctors(
          token: token,
          area: 'Chembur',
          city: 'Mumbai',
          date: _isoDate(_selectedDate),
        );
  }

  String _isoDate(DateTime value) => value.toIso8601String().split('T').first;
}

class _DoctorBookingDraft {
  const _DoctorBookingDraft({
    required this.date,
    required this.time,
    required this.reason,
  });

  final String date;
  final String time;
  final String reason;
}

class _DoctorBookingDialog extends StatefulWidget {
  const _DoctorBookingDialog({
    required this.doctorName,
    required this.category,
    required this.initialDate,
  });

  final String doctorName;
  final String category;
  final DateTime initialDate;

  @override
  State<_DoctorBookingDialog> createState() => _DoctorBookingDialogState();
}

class _DoctorBookingDialogState extends State<_DoctorBookingDialog> {
  final _reasonController = TextEditingController();
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Book ${widget.doctorName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Date: ${_date.toIso8601String().split('T').first}')),
                IconButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range_rounded),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Time: ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) {
                      setState(() => _time = picked);
                    }
                  },
                  icon: const Icon(Icons.access_time_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
              _DoctorBookingDraft(
                date: _date.toIso8601String().split('T').first,
                time: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00',
                reason: _reasonController.text.trim(),
              ),
            );
          },
          child: const Text('Book'),
        ),
      ],
    );
  }
}
