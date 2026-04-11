import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const baseGreen = Color(0xFF2E8B7E);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseGreen,
      brightness: Brightness.light,
    );
    const cardRadius = 22.0;
    const inputRadius = 18.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF15221F)),
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF15221F)),
        headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Color(0xFF15221F)),
        titleLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, color: Color(0xFF15221F)),
        titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF15221F)),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF22322E)),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF334641)),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Color(0x22000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: Color(0xFFE1E8E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: Color(0xFFE1E8E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
