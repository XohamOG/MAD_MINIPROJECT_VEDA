import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class DigitalPrescriptionScreen extends StatefulWidget {
  const DigitalPrescriptionScreen({super.key});

  @override
  State<DigitalPrescriptionScreen> createState() => _DigitalPrescriptionScreenState();
}

class _DigitalPrescriptionScreenState extends State<DigitalPrescriptionScreen> {
  static const String _prescriptionsPrefsKey = 'digital_prescriptions_local';

  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedFilePath;
  final List<_PrescriptionEntry> _entries = <_PrescriptionEntry>[];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Digital Prescription';
    _dateController.text = DateTime.now().toIso8601String().split('T').first;
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
          child: Form(
            key: _formKey,
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
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Prescription title'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a title.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Prescription date',
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Select a date.' : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _dateController.text = picked.toIso8601String().split('T').first);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _selectedFilePath == null
                    ? const Card(
                        color: Color(0xFFF4FAF9),
                        child: ListTile(
                          leading: Icon(Icons.description_outlined, color: Color(0xFF16878F)),
                          title: Text('No prescription selected yet'),
                          subtitle: Text('Pick a photo or document to preview before uploading.'),
                        ),
                      )
                    : _FilePreviewCard(
                        filePath: _selectedFilePath!,
                        onClear: () => setState(() => _selectedFilePath = null),
                      ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savePrescription,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Save Prescription'),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Saved Prescriptions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_entries.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('No digital prescriptions saved yet.'),
                    ),
                  )
                else
                  ..._entries.map(
                    (entry) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEAF3FF),
                          child: Icon(Icons.description_rounded, color: Color(0xFF2F78DD)),
                        ),
                        title: Text(entry.title),
                        subtitle: Text('${entry.date}\n${entry.fileName}'),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scanPrescription() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted || image == null) return;
    setState(() {
      _selectedFilePath = image.path;
    });
  }

  Future<void> _uploadFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || result == null || result.files.single.path == null) return;
    setState(() {
      _selectedFilePath = result.files.single.path!;
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    final filePath = _selectedFilePath;
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first.')));
      return;
    }
    if (!File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected file was not found.')));
      return;
    }

    final entry = _PrescriptionEntry(
      title: _titleController.text.trim(),
      date: _dateController.text.trim(),
      filePath: filePath,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() => _entries.insert(0, entry));
    await _persistPrescriptions();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription saved to Digital Prescription vault.')),
    );
    setState(() {
      _selectedFilePath = null;
      _notesController.clear();
    });
  }

  Future<void> _loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prescriptionsPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded
          .whereType<Map<String, dynamic>>()
          .map(_PrescriptionEntry.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // Ignore invalid local cache and continue.
    }
  }

  Future<void> _persistPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_prescriptionsPrefsKey, encoded);
  }
}

class _PrescriptionEntry {
  const _PrescriptionEntry({
    required this.title,
    required this.date,
    required this.filePath,
    required this.notes,
    required this.createdAt,
  });

  final String title;
  final String date;
  final String filePath;
  final String notes;
  final String createdAt;

  String get fileName {
    final parts = filePath.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? filePath : parts.last;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'file_path': filePath,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory _PrescriptionEntry.fromJson(Map<String, dynamic> json) {
    return _PrescriptionEntry(
      title: (json['title'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      filePath: (json['file_path'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class _FilePreviewCard extends StatelessWidget {
  const _FilePreviewCard({
    required this.filePath,
    required this.onClear,
  });

  final String filePath;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile(filePath);
    final fileName = _fileName(filePath);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE5F0)),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 78,
              height: 78,
              color: const Color(0xFFF4F7FB),
              child: isImage
                  ? Image.file(File(filePath), fit: BoxFit.cover)
                  : const Icon(Icons.picture_as_pdf_rounded, size: 42, color: Color(0xFF16878F)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preview', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(isImage ? 'Image ready to upload' : 'Document ready to upload', style: const TextStyle(color: Color(0xFF667085))),
              ],
            ),
          ),
          IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }

  bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp');
  }

  String _fileName(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
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
