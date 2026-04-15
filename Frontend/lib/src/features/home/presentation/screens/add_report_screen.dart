import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({
    super.key,
    this.initialFilePath,
    this.initialCategory,
    this.initialUploadMode,
  });

  final String? initialFilePath;
  final String? initialCategory;
  final String? initialUploadMode;

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Blood Test';
  String _uploadMode = 'Upload File';
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedFilePath;
  final _categories = const ['Blood Test', 'Scan', 'Prescription', 'Discharge', 'General'];

  @override
  void initState() {
    super.initState();
    _selectedFilePath = widget.initialFilePath?.isNotEmpty == true ? widget.initialFilePath : null;
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _category = widget.initialCategory!;
    }
    if (widget.initialUploadMode != null && widget.initialUploadMode!.isNotEmpty) {
      _uploadMode = widget.initialUploadMode!;
    }
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
    final health = context.watch<HealthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medical Report'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Upload Document', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _UploadOptionTile(
                  icon: Icons.photo_camera_rounded,
                  iconColor: const Color(0xFF9C27B0),
                  title: 'Take Photo',
                  subtitle: 'Use camera to capture',
                  onTap: _pickFromCamera,
                  selected: _uploadMode == 'Take Photo',
                ),
                const SizedBox(height: 10),
                _UploadOptionTile(
                  icon: Icons.upload_file_rounded,
                  iconColor: const Color(0xFF4A90E2),
                  title: 'Upload File',
                  subtitle: 'Select image or PDF',
                  onTap: _pickFromFiles,
                  selected: _uploadMode == 'Upload File',
                ),
                const SizedBox(height: 12),
                Text('Select Category *', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(item),
                              selected: _category == item,
                              onSelected: (_) => setState(() => _category = item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Report title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter report title.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Report date',
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Select report date.' : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      _dateController.text = picked.toIso8601String().split('T').first;
                    }
                  },
                ),
                const SizedBox(height: 12),
                _selectedFilePath == null
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE3E6EE)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No file selected', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Choose a photo or PDF to preview before uploading.'),
                          ],
                        ),
                      )
                    : _DocumentPreviewCard(
                        filePath: _selectedFilePath!,
                        onClear: () => setState(() => _selectedFilePath = null),
                      ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: health.isUploadingReport ? null : _submit,
                    child: health.isUploadingReport
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Upload report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final filePath = _selectedFilePath;
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first.')));
      return;
    }
    if (!File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found at given path.')));
      return;
    }

    final token = context.read<AuthController>().token;
    if (token == null || token.isEmpty) return;

    final ok = await context.read<HealthController>().uploadReport(
          token: token,
          title: _titleController.text.trim(),
          reportType: _category,
          reportDate: _dateController.text.trim(),
          filePath: filePath,
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Report uploaded.' : context.read<HealthController>().errorMessage ?? 'Failed')),
    );
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _pickFromCamera() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;
    setState(() {
      _uploadMode = 'Take Photo';
      _selectedFilePath = image.path;
    });
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _uploadMode = 'Upload File';
      _selectedFilePath = result.files.single.path!;
    });
  }
}

class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard({
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFF4F7FB),
              child: isImage
                  ? Image.file(File(filePath), fit: BoxFit.cover)
                  : const Icon(Icons.picture_as_pdf_rounded, size: 40, color: Color(0xFF2F78DD)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected file', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(isImage ? 'Image preview' : 'Document preview', style: const TextStyle(color: Color(0xFF667085))),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
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

class _UploadOptionTile extends StatelessWidget {
  const _UploadOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.selected,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFF8D43C8) : const Color(0xFFE3E3EA), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF667085))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
