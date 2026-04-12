import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return SafeArea(
      child: Column(
        children: [
          const GradientHeader(
            title: 'Profile',
            subtitle: 'Personal and health details',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName : 'Ashray User',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(user?.email ?? 'No email'),
                        Text('Phone: ${user?.phone ?? '--'}'),
                        Text('Age: ${_ageFromDob(user?.dateOfBirth) ?? '--'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ActionCard(
                  title: 'Health info',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blood Group: ${user?.bloodGroup?.isNotEmpty == true ? user!.bloodGroup! : '--'}'),
                      const SizedBox(height: 6),
                      const Text('Allergies: --'),
                      const SizedBox(height: 6),
                      Text(
                        'Emergency Contact: ${user?.emergencyContactName?.isNotEmpty == true ? user!.emergencyContactName! : '--'}'
                        '${user?.emergencyContactPhone?.isNotEmpty == true ? ' (${user!.emergencyContactPhone})' : ''}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<AuthController>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _ageFromDob(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    final parts = dob.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final birth = DateTime(year, month, day);
    final today = DateTime.now();
    var age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age -= 1;
    }
    return age.toString();
  }
}
