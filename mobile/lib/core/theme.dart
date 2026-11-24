import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFBF7F5);
  static const text = Color(0xFF231619);
  static const muted = Color(0xFF6B5A5E);
  static const border = Color(0xFFE6DAD6);
  static const primary = Color(0xFFB42318);
  static const primarySoft = Color(0xFFFDECEA);
  static const teal = Color(0xFF0B6B5C);
  static const tealSoft = Color(0xFFE1F2EE);
  static const amber = Color(0xFF7A4B00);
  static const amberSoft = Color(0xFFFFF0D6);
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: BorderSide(color: color),
);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: _border(const Color(0xFFD9CCC8)),
      enabledBorder: _border(const Color(0xFFD9CCC8)),
      focusedBorder: _border(AppColors.primary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
