import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/core/constants/app_colors.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/health_dashboard_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/medication_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/digital_prescription_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/find_doctor_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/notification_simulator_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/sensor_simulation_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/profile_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/reports_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/schedule_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/sos_screen.dart';
import 'package:veda_app/src/features/home/presentation/screens/add_report_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _didInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialLoad) return;

    final auth = context.watch<AuthController>();
    final token = auth.token;
    if (token != null && token.isNotEmpty) {
      _didInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final health = context.read<HealthController>();
        health.loadDashboard(token);
        health.startAutoSync(token);
      });
    }
  }

  @override
  void dispose() {
    context.read<HealthController>().stopAutoSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeDashboardScreen(
        onOpenTab: _jumpToTab,
        onOpenMedication: _openMedicationScreen,
        onOpenFindDoctor: _openFindDoctorScreen,
        onOpenDigitalPrescription: _openDigitalPrescriptionScreen,
        onOpenAddReport: _openAddReportScreen,
        onOpenHealthDashboard: _openHealthDashboardScreen,
        onOpenNotificationSimulator: _openNotificationSimulatorScreen,
        onOpenSensorSimulation: _openSensorSimulationScreen,
      ),
      const ScheduleScreen(),
      const ReportsScreen(),
      const SosScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBF2EA),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_rounded, color: Color(0xFFC62828)),
            label: 'SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _jumpToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openMedicationScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => const Scaffold(body: SafeArea(child: MedicationScreen())),
      ),
    );
  }

  void _openAddReportScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddReportScreen()));
  }

  void _openDigitalPrescriptionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => const Scaffold(
              body: SafeArea(child: DigitalPrescriptionScreen()),
            ),
      ),
    );
  }

  void _openFindDoctorScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => const Scaffold(body: SafeArea(child: FindDoctorScreen())),
      ),
    );
  }

  void _openHealthDashboardScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) =>
                const Scaffold(body: SafeArea(child: HealthDashboardScreen())),
      ),
    );
  }

  void _openNotificationSimulatorScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => const Scaffold(
              body: SafeArea(child: NotificationSimulatorScreen()),
            ),
      ),
    );
  }

  void _openSensorSimulationScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) =>
                const Scaffold(body: SafeArea(child: SensorSimulationScreen())),
      ),
    );
  }
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.splashGradientTop, AppColors.splashGradientBottom],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFEAF8F2),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: const Color(0xFF1D7E68)),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
