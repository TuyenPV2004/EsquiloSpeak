import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFFE65100); // Deep Orange (Squirrel)
  static const Color accentColor = Color(0xFFFFB74D); // Light Orange
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: const Color(0xFF3E2723), // Warm brown
      surface: const Color(0xFFFFFDF9), // Warm eggshell white
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFDF9),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.black87,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: accentColor,
      secondary: const Color(0xFFD7CCC8),
      surface: const Color(0xFF0F0F1A), // Deep dark space/navy
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F1A),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.white70,
      ),
    ),
  );
}
