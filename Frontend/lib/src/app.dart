import 'package:flutter/material.dart';

import 'package:veda_app/src/features/home/presentation/home_page.dart';
import 'package:veda_app/src/theme/app_theme.dart';

class VedaApp extends StatelessWidget {
  const VedaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomePage(),
    );
  }
}
