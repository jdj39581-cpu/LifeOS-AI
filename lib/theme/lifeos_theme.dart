import 'package:flutter/material.dart';

class LifeOSTheme {
  static const bg = Color(0xFF0F172A);
  static const card = Color(0xFF1E293B);
  static const cyan = Color(0xFF06B6D4);
  static const purple = Color(0xFF7C3AED);

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: cyan,
      foregroundColor: Colors.white,
    ),
  );
}
