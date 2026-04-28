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
    final name = user?.fullName.isNotEmpty == true ? user!.fullName : 'Ashray User';
    final email = user?.email.isNotEmpty == true ? user!.email : 'No email';
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : '--';
    final age = _ageFromDob(user?.dateOfBirth) ?? '--';
    final bloodGroup = user?.bloodGroup?.isNotEmpty == true ? user!.bloodGroup! : '--';
    final bp = user?.bpReading?.isNotEmpty == true ? user!.bpReading! : '--';
    final sugar = user?.sugarLevel?.isNotEmpty == true ? user!.sugarLevel! : '--';
    final heartRate = user?.heartRate?.isNotEmpty == true ? user!.heartRate! : '--';
    final weight = user?.weight?.isNotEmpty == true ? user!.weight! : '--';

    return SafeArea(
      child: Column(
        children: [
          const GradientHeader(
            title: 'Profile',
            subtitle: 'Manage your account settings',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Patient ID: #ELD2024-001',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(icon: Icons.email_outlined, text: email),
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.phone_outlined, text: phone),
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.cake_outlined, text: 'Age: $age years'),
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.place_outlined, text: bloodGroup == '--' ? 'Location: --' : 'Blood group: $bloodGroup'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ActionCard(
                  title: 'Health Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.35,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          _HealthMetricCard(title: 'Blood Type', value: bloodGroup),
                          _HealthMetricCard(title: 'BP', value: bp),
                          _HealthMetricCard(title: 'Heart Rate', value: '$heartRate bpm'),
                          _HealthMetricCard(title: 'Weight', value: '$weight kg'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
