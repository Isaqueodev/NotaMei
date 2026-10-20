import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/theme/notamei_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('brand and both fonts are bundled for offline rendering', () async {
    for (final asset in [
      'assets/brand/notamei.png',
      'assets/fonts/Inter.ttf',
      'assets/fonts/PlayfairDisplay.ttf',
    ]) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(1000));
    }
  });
  test('V5 uses paper, ink, local editorial fonts and flat surfaces', () {
    final theme = NotaMeiTheme.data;
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFAF8F5));
    expect(theme.colorScheme.primary, const Color(0xFF1E1735));
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
    expect(theme.textTheme.headlineSmall?.fontFamily, 'Playfair Display');
    expect(theme.textTheme.bodyLarge?.fontSize, 16);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.navigationBarTheme.backgroundColor, Colors.white);
    expect(theme.navigationBarTheme.elevation, 0);
  });
}
