import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';
import 'package:veda_app/src/features/home/presentation/screens/add_report_screen.dart';

class DigitalPrescriptionScreen extends StatefulWidget {
  const DigitalPrescriptionScreen({super.key});

  @override
  State<DigitalPrescriptionScreen> createState() => _DigitalPrescriptionScreenState();
}

class _DigitalPrescriptionScreenState extends State<DigitalPrescriptionScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF23B5A9), Color(0xFF16878F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digital Prescription',
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Upload and view your prescriptions',
                style: TextStyle(color: Color(0xFFDDF8F6), fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ActionTile(
                icon: Icons.photo_camera_rounded,
                iconColor: const Color(0xFF16B7A8),
                title: 'Scan Prescription',
                subtitle: 'Use camera to capture',
                onTap: _scanPrescription,
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.upload_file_rounded,
                iconColor: const Color(0xFF4A90E2),
                title: 'Upload from Device',
                subtitle: 'Select image or PDF',
                onTap: _uploadFromDevice,
              ),
              const SizedBox(height: 14),
              const Card(
                color: Color(0xFFEAF3FF),
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: Color(0xFF3D7CD8)),
                  title: Text(
                    'Digital prescription is for reference only.\nAlways verify with original document.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _scanPrescription() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted || image == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddReportScreen(
          initialFilePath: image.path,
          initialCategory: 'Prescription',
          initialUploadMode: 'Take Photo',
        ),
      ),
    );
  }

  Future<void> _uploadFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || result == null || result.files.single.path == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddReportScreen(
          initialFilePath: result.files.single.path!,
          initialCategory: 'Prescription',
          initialUploadMode: 'Upload File',
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1F2D3D)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6C7A89), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
