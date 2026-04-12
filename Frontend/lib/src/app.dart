import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veda_app/src/core/network/api_service.dart';
import 'package:veda_app/src/features/auth/data/token_storage.dart';
import 'package:veda_app/src/features/auth/presentation/auth_controller.dart';
import 'package:veda_app/src/features/auth/presentation/create_account_screen.dart';
import 'package:veda_app/src/features/auth/presentation/login_screen.dart';
import 'package:veda_app/src/features/auth/presentation/splash_screen.dart';
import 'package:veda_app/src/features/health/presentation/health_controller.dart';
import 'package:veda_app/src/features/home/presentation/home_page.dart';
import 'package:veda_app/src/theme/app_theme.dart';

class VedaApp extends StatelessWidget {
  const VedaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(
            apiService: apiService,
            tokenStorage: TokenStorage(),
          )..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => HealthController(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Veda',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          CreateAccountScreen.routeName: (context) => const CreateAccountScreen(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
