import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
                                    backgroundColor: Color(0xFFFFE8E8),
                                    child: Icon(Icons.description_rounded, color: Color(0xFFD94242)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (report['title'] ?? 'Report').toString(),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          (report['report_type'] ?? 'General').toString(),
                                          style: const TextStyle(color: Color(0xFFD94242), fontWeight: FontWeight.w700),
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
                                      onPressed: () => _openReport(report),
                                      icon: const Icon(Icons.visibility_rounded),
                                      label: const Text('View'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2F78DD),
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

  Future<void> _openReport(Map<String, dynamic> report) async {
    final fileValue = (report['file'] ?? '').toString().trim();
    if (fileValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report file is attached.')),
      );
      return;
    }

    final uri = _resolveReportUri(fileValue);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the report file.')),
      );
    }
  }

  Uri _resolveReportUri(String fileValue) {
    final parsed = Uri.tryParse(fileValue);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final apiUri = Uri.parse(AppConfig.baseUrl);
    final origin = '${apiUri.scheme}://${apiUri.authority}';
    final normalizedPath = fileValue.startsWith('/') ? fileValue.substring(1) : fileValue;
    return Uri.parse('$origin/$normalizedPath');
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
