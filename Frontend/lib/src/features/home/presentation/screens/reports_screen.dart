import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/core/config/app_config.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/screens/add_report_screen.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  static const _filters = ['All', 'Blood Test', 'Scan', 'Prescription', 'Discharge'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final health = context.watch<HealthController>();
    final token = auth.token;
    final query = _searchController.text.trim().toLowerCase();

    final reports = health.reports.where((report) {
      final type = (report['report_type'] ?? '').toString();
      if (type.toLowerCase() == 'digital prescription') {
        return false;
      }
      final title = (report['title'] ?? '').toString();
      final matchesFilter = _selectedFilter == 'All' || type.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesSearch = query.isEmpty || title.toLowerCase().contains(query) || type.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7DE2), Color(0xFF1E63C2)],
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
                  'Medical Reports',
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'View and manage your health records',
                  style: TextStyle(color: Color(0xFFDDEBFF), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (token != null && token.isNotEmpty) {
                  await context.read<HealthController>().fetchReports(token);
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search reports',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final selected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: selected,
                            label: Text(filter),
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (health.isLoadingReports)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (reports.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('No reports found. Add your first report.'),
                      ),
                    )
                  else
                    ...reports.map((report) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFEAF3FF),
                                    child: Icon(Icons.description_rounded, color: Color(0xFF2F78DD)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (report['title'] ?? 'Report').toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          (report['report_type'] ?? 'General').toString(),
                                          style: const TextStyle(color: Color(0xFF5B88CC), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Date: ${(report['report_date'] ?? '')}'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _previewReport(report),
                                      icon: const Icon(Icons.visibility_rounded),
                                      label: const Text('View Report'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE8F1FF),
                                        foregroundColor: const Color(0xFF2F78DD),
                                        elevation: 0,
                                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _MiniIconButton(
                                    icon: Icons.download_rounded,
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 6),
                                  _MiniIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    onTap: () => _deleteReport(report['id'] as int?),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const AddReportScreen()),
                      );
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Add New Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF47B653),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Card(
                    color: Color(0xFFE9F4EB),
                    child: ListTile(
                      leading: Icon(Icons.lock_outline_rounded, color: Color(0xFF3CA95A)),
                      title: Text('Your medical records are securely encrypted and protected.'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(int? id) async {
    if (id == null) return;
    final token = context.read<AuthController>().token;
    if (token == null || token.isEmpty) return;
    final ok = await context.read<HealthController>().deleteReport(token: token, id: id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Report deleted.' : context.read<HealthController>().errorMessage ?? 'Delete failed')),
    );
  }

  Future<void> _previewReport(Map<String, dynamic> report) async {
    final fileValue = (report['file'] ?? report['file_url'] ?? '').toString();
    if (fileValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No document attached for this report.')));
      return;
    }

    final resolvedUrl = _resolveMediaUrl(fileValue);
    final fileName = _fileName(fileValue);
    final isImage = _isImageFile(fileValue);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text((report['title'] ?? 'Report').toString()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            resolvedUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 58, color: Color(0xFF2F78DD)),
                            const SizedBox(height: 10),
                            Text(fileName, textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            const Text('PDF document preview', style: TextStyle(color: Color(0xFF667085))),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _resolveMediaUrl(String fileValue) {
    if (fileValue.startsWith('http://') || fileValue.startsWith('https://')) {
      return fileValue;
    }
    final baseUri = Uri.parse(AppConfig.baseUrl);
    final root = baseUri.replace(path: '');
    if (fileValue.startsWith('/')) {
      return root.resolve(fileValue).toString();
    }
    return root.resolve('/$fileValue').toString();
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

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF667085)),
      ),
    );
  }
}
