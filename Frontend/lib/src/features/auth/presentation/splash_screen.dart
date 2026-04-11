import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/core/constants/app_colors.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/auth/presentation/create_account_screen.dart';
import 'package:veda_app/src/features/auth/presentation/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();
    if (!_redirected && !auth.isCheckingSession && auth.isAuthenticated) {
      _redirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.splashGradientTop, AppColors.splashGradientBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Color(0xFF218C6D), size: 62),
                ),
                const SizedBox(height: 22),
                Text(
                  'Ashray',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Healthcare support for every day',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: const Color(0xFFEAF8F2)),
                ),
                const Spacer(flex: 3),
                if (auth.isCheckingSession)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 26),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(LoginScreen.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.darkText,
                      ),
                      child: const Text('Log in'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(CreateAccountScreen.routeName);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        side: const BorderSide(color: Colors.white, width: 1.7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text(
                        'Create account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
