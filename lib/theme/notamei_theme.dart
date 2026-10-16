import 'package:flutter/material.dart';

abstract final class NotaMeiTheme {
  static const purple = Color(0xFF6C31C7);
  static const palePurple = Color(0xFFF8F3FF);
  static const ink = Color(0xFF17131C);
  static const muted = Color(0xFF655D6D);
  static const border = Color(0xFFE9E4EC);
  static const mint = Color(0xFFDDF7F2);

  static ThemeData get data {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.light,
        ).copyWith(
          primary: purple,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: ink,
        );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          height: 1.12,
        ),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 15, height: 1.35),
        bodyMedium: TextStyle(fontSize: 13, height: 1.35),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x16000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          minimumSize: const Size.fromHeight(42),
          side: const BorderSide(color: purple),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
