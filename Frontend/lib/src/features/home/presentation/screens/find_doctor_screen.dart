import 'package:flutter/material.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final _searchController = TextEditingController();
  String _selected = 'General';
  final _filters = const ['General', 'Cardiologist', 'Dermatologist', 'Neurologist', 'Pediatrician'];

  final _doctors = const [
    {'name': 'Dr. Aarav Mehta', 'specialty': 'General', 'rating': '4.8', 'distance': '1.2 km'},
    {'name': 'Dr. Kavya Iyer', 'specialty': 'Cardiologist', 'rating': '4.9', 'distance': '2.0 km'},
    {'name': 'Dr. Rohan Das', 'specialty': 'Neurologist', 'rating': '4.6', 'distance': '3.4 km'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final visible = _doctors.where((doc) {
      final specialty = (doc['specialty'] ?? '').toLowerCase();
      final name = (doc['name'] ?? '').toLowerCase();
      final filterOk = _selected.toLowerCase() == specialty || _selected == 'General';
      final queryOk = query.isEmpty || name.contains(query) || specialty.contains(query);
      return filterOk && queryOk;
    }).toList();

    return Column(
      children: [
        const GradientHeader(
          title: 'Find Doctor',
          subtitle: 'Discover nearby specialists',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search doctors',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(item),
                            selected: _selected == item,
                            onSelected: (_) => setState(() => _selected = item),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              ...visible.map(
                (doc) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (doc['name'] ?? '').toString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text('${doc['specialty']} • ⭐ ${doc['rating']} • ${doc['distance']}'),
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
                                onPressed: () {},
                                icon: const Icon(Icons.calendar_today_rounded),
                                label: const Text('Book'),
                              ),
                            ),
                          ],
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
    );
  }
}
