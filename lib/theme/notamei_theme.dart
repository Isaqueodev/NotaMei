import 'package:flutter/material.dart';

/// Editorial B tokens. Legacy names remain aliases during the visual migration.
abstract final class NotaMeiTheme {
  static const primary = Color(0xFF142D4E);
  static const destaque = Color(0xFF28B889);
  static const fundo = Color(0xFFF4F7FA);

  static const ink = primary;
  static const paper = fundo;
  static const muted = Color(0xFF5F6B7A);
  static const border = Color(0xFFDCE3EC);
  static const income = Color(0xFF28B889);
  static const expense = Color(0xFFD64545);
  static const incomeDark = Color(0xFFA9F5D1);
  static const expenseDark = Color(0xFFFFB7AE);
  static const clay = destaque;
  static const purple = primary;
  static const palePurple = fundo;
  static const mint = Color(0xFFEFFAF6);

  static ThemeData get data {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: destaque,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: primary,
          onSurfaceVariant: muted,
          outline: border,
          error: expense,
          surfaceTint: Colors.transparent,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
    );

    final text = base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: primary,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: primary,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: primary,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        height: 1.45,
        color: primary,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        height: 1.45,
        color: primary,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        height: 1.35,
        color: muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return base.copyWith(
      textTheme: text,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: destaque,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
    );
  }
}
