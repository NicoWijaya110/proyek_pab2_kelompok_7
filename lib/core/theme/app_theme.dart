// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  // Warna utama neon cyan (tema gaming)
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B8D4);
  static const Color accent = Color(0xFF7C4DFF);

  // Background
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF12121A);
  static const Color darkCard = Color(0xFF1A1A26);
  static const Color darkBorder = Color(0xFF2A2A38);

  // Light mode
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFEEEEEE);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textDark = Color(0xFF1A1A2E);

  // Status
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFD740);

  // Genre colors
  static const Map<String, Color> _genreColors = {
    'Action':     Color(0xFFFF5252),
    'RPG':        Color(0xFF7C4DFF),
    'Strategy':   Color(0xFF00E5FF),
    'Sports':     Color(0xFF69F0AE),
    'Horror':     Color(0xFFFF6D00),
    'Adventure':  Color(0xFFFFD740),
    'Simulation': Color(0xFF40C4FF),
    'Puzzle':     Color(0xFFE040FB),
    'Racing':     Color(0xFF00E676),
    'Fighting':   Color(0xFFFF4081),
  };

  static Color genreColor(String genre) {
    return _genreColors[genre] ?? primary;
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: AppColors.darkBg,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,

      // Font
      fontFamily: 'Exo2',
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: 'Orbitron', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Orbitron', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displaySmall:  TextStyle(fontFamily: 'Orbitron', color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Orbitron', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium:TextStyle(fontFamily: 'Orbitron', color: AppColors.textPrimary),
        titleLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: AppColors.textPrimary),
        bodyLarge:     TextStyle(color: AppColors.textPrimary),
        bodyMedium:    TextStyle(color: AppColors.textSecondary),
        labelLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Exo2', fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // Input field
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.primary,
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.primary, fontFamily: 'Exo2', fontWeight: FontWeight.bold);
          }
          return const TextStyle(color: AppColors.textSecondary, fontFamily: 'Exo2');
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCard,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Exo2'),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkCard,
        thickness: 1,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkBg,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDark,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,

      fontFamily: 'Exo2',
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: 'Orbitron', color: AppColors.textDark, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Orbitron', color: AppColors.textDark, fontWeight: FontWeight.bold),
        titleLarge:    TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        bodyMedium:    TextStyle(color: AppColors.textDark),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Exo2', fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: AppColors.primaryDark,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
    );
  }
}