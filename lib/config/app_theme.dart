import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF003366), // University typical blue
        primary: const Color(0xFF003366),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
    );
  }
}
