import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _showEditDialog() async {
    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) return;

    final fullNameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final bloodGroupController = TextEditingController(text: user.bloodGroup ?? '');
    final emergencyNameController = TextEditingController(text: user.emergencyContactName ?? '');
    final emergencyPhoneController = TextEditingController(text: user.emergencyContactPhone ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 8),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 8),
                TextField(controller: bloodGroupController, decoration: const InputDecoration(labelText: 'Blood group')),
                const SizedBox(height: 8),
                TextField(
                  controller: emergencyNameController,
                  decoration: const InputDecoration(labelText: 'Emergency contact name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emergencyPhoneController,
                  decoration: const InputDecoration(labelText: 'Emergency contact phone(s)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
          ],
        );
      },
    );

    if (result != true) {
      fullNameController.dispose();
      phoneController.dispose();
      bloodGroupController.dispose();
      emergencyNameController.dispose();
      emergencyPhoneController.dispose();
      return;
    }

    final ok = await auth.updateProfile(
      payload: {
        'full_name': fullNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'blood_group': bloodGroupController.text.trim(),
        'emergency_contact_name': emergencyNameController.text.trim(),
        'emergency_contact_phone': emergencyPhoneController.text.trim(),
      },
    );

    fullNameController.dispose();
    phoneController.dispose();
    bloodGroupController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Profile updated.' : auth.errorMessage ?? 'Profile update failed.')),
    );
  }

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
                  onPressed: auth.isLoading ? null : _showEditDialog,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit profile'),
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
