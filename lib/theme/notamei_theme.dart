import 'package:flutter/material.dart';

/// Editorial B tokens. Legacy names remain aliases during the visual migration.
abstract final class NotaMeiTheme {
  static const ink = Color(0xFF1E1735);
  static const paper = Color(0xFFFAF8F5);
  static const muted = Color(0xFF615B6B);
  static const border = Color(0xFFE5E0D8);
  static const income = Color(0xFF28724B);
  static const expense = Color(0xFFB23836);
  static const incomeDark = Color(0xFFA9E4B7);
  static const expenseDark = Color(0xFFFFB7AE);
  static const clay = Color(0xFFA65D47);
  static const purple = ink;
  static const palePurple = paper;
  static const mint = Color(0xFFEDF5EE);

  static ThemeData get data {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: ink,
          brightness: Brightness.light,
        ).copyWith(
          primary: ink,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: border,
          error: expense,
          surfaceTint: Colors.transparent,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
    );
    final text = base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: ink,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        height: 1.45,
        color: ink,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.45,
        color: ink,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.35,
        color: muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: paper,
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: ink),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paper,
        selectedColor: ink,
        secondarySelectedColor: ink,
        side: const BorderSide(color: border),
        shape: shape,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: paper,
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
      ),
    );
  }
}
