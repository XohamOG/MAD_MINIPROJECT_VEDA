import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/home/presentation/main_shell.dart';
import 'package:veda_app/src/features/home/presentation/screens/doctor_dashboard_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.isDoctor) {
      return const DoctorDashboardScreen();
    }
    return const MainShell();
  }
}
