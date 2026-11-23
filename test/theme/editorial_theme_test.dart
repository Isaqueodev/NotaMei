import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/theme/notamei_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('marca, Roboto e fonte do PDF estão disponíveis offline', () async {
    for (final asset in [
      'assets/brand/notamei.png',
      'assets/fonts/Inter.ttf',
      'assets/fonts/Roboto-Regular.ttf',
      'assets/fonts/Roboto-Medium.ttf',
      'assets/fonts/Roboto-Bold.ttf',
    ]) {
      expect(
        (await rootBundle.load(asset)).lengthInBytes,
        greaterThan(1000),
        reason: asset,
      );
    }
  });

  for (final dark in [false, true]) {
    test('tema ${dark ? 'escuro' : 'claro'} usa Roboto e a paleta atual', () {
      final theme = dark ? NotaMeiTheme.darkData : NotaMeiTheme.data;
      expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
      expect(
        theme.scaffoldBackgroundColor,
        dark ? const Color(0xFF0F1420) : const Color(0xFFF4F7FA),
      );
      expect(
        theme.colorScheme.primary,
        dark ? const Color(0xFF9BB4FF) : const Color(0xFF142D4E),
      );
      expect(
        theme.colorScheme.surface,
        dark ? const Color(0xFF151B2B) : Colors.white,
      );
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Roboto');
      expect(theme.textTheme.headlineSmall?.fontFamily, 'Roboto');
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.cardTheme.color, theme.colorScheme.surface);
      expect(theme.cardTheme.elevation, 0);
    });
  }
}
