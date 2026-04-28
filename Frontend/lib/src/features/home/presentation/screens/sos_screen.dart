import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _resolvingLocation = false;
  double? _latitude;
  double? _longitude;
  String _locationStatus = 'Location not fetched yet';

  @override
  void initState() {
    super.initState();
    _resolveCurrentLocation();
  }

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
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_rounded, color: Color(0xFFB71C1C)),
                    title: const Text('Location sharing'),
                    subtitle: Text(
                      'SOS sends location and opens an SMS draft for your emergency contact numbers.',
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

    final user = auth.user;

    setState(() => _sending = true);

    Position? position;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        }
      }
    } catch (_) {
      // Continue SOS flow even if location cannot be fetched.
    }

    final locationText = position == null
        ? 'Location unavailable'
        : 'https://maps.google.com/?q=${_roundTo6(position.latitude)},${_roundTo6(position.longitude)}';
    final message = _messageController.text.trim().isEmpty ? 'Need immediate help' : _messageController.text.trim();
    final sosMessage = '$message | $locationText';

    final ok = await context.read<HealthController>().triggerSos(
          token: token,
          message: sosMessage,
          latitude: position == null ? null : _roundTo6(position.latitude),
          longitude: position == null ? null : _roundTo6(position.longitude),
        );

    if (ok) {
      final phones = _parseEmergencyPhones(user?.emergencyContactPhone);
      if (phones.isNotEmpty) {
        final smsBody = Uri.encodeComponent(
          'SOS from ${user?.fullName ?? 'patient'}: $message\nLocation: $locationText',
        );
        final recipients = Uri.encodeComponent(phones.join(','));
        final smsUri = Uri.parse('sms:$recipients?body=$smsBody');
        await launchUrl(smsUri);
      }
    }

    if (!mounted) return;
    setState(() => _sending = false);

    final hasContact = _parseEmergencyPhones(user?.emergencyContactPhone).isNotEmpty;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (hasContact
                  ? 'Emergency alert sent with location.'
                  : 'Emergency alert logged. Add emergency phone in profile to send SMS.')
              : context.read<HealthController>().errorMessage ?? 'Failed',
        ),
      ),
    );
  }

  List<String> _parseEmergencyPhones(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String>[];
    return raw
        .split(RegExp(r'[;,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  double _roundTo6(double value) {
    return double.parse(value.toStringAsFixed(6));
  }
}
