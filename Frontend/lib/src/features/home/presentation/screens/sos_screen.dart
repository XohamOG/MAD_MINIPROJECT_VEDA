import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _messageController = TextEditingController(text: 'Need immediate help');
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const GradientHeader(
            title: 'Emergency SOS',
            subtitle: 'Tap once to alert your emergency contact and care team',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFFFFECEC),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'SOS Alert',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFC62828)),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _sending ? null : _triggerSos,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC62828),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0x44C62828), blurRadius: 18, offset: Offset(0, 8)),
                              ],
                            ),
                            child: Center(
                              child: _sending
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 54,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Tap for Help',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFB71C1C)),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Emergency message',
                            prefixIcon: Icon(Icons.message_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.location_on_rounded, color: Color(0xFFB71C1C)),
                    title: Text('Location sharing'),
                    subtitle: Text(
                      'Current location is shared with emergency responders when SOS is pressed.',
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

  Future<void> _triggerSos() async {
    final auth = context.read<AuthController>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;

    setState(() => _sending = true);
    final ok = await context.read<HealthController>().triggerSos(
          token: token,
          message: _messageController.text.trim().isEmpty ? 'Need immediate help' : _messageController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Emergency alert sent.' : context.read<HealthController>().errorMessage ?? 'Failed')),
    );
  }
}
