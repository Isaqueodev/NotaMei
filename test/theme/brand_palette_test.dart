import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Android launcher and in-app N use the same V5 palette', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final density in sizes.entries) {
        final bytes = await File(
          'android/app/src/main/res/mipmap-${density.key}/ic_launcher.png',
        ).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        expect(image.width, density.value);
        expect(image.height, density.value);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final colors = <int>{};
        for (var i = 0; i < data.lengthInBytes; i += 4) {
          if (data.getUint8(i + 3) == 255) {
            colors.add(
              (data.getUint8(i) << 16) |
                  (data.getUint8(i + 1) << 8) |
                  data.getUint8(i + 2),
            );
          }
        }
        expect(
          colors,
          containsAll([0x1E1735, 0xFAF8F5, 0x28724B]),
          reason: density.key,
        );
        expect(
          colors.contains(0x6D3FC6),
          isFalse,
          reason: 'Old purple on ${density.key}',
        );
        expect(
          colors.contains(0x24CAA9),
          isFalse,
          reason: 'Old turquoise on ${density.key}',
        );
        image.dispose();
        codec.dispose();
      }
      expect(
        await File('assets/brand/notamei.png').readAsBytes(),
        orderedEquals(
          await File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png')
              .readAsBytes(),
        ),
        reason: 'The in-app logo and high-resolution launcher must share the exact bitmap',
      );
    });
  });
}
