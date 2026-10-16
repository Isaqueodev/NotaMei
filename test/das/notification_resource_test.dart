import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android bundles a drawable icon for DAS notifications', () {
    final icon = File('android/app/src/main/res/drawable/ic_notification.xml');
    expect(icon.existsSync(), isTrue);
    final source = icon.readAsStringSync();
    expect(source, contains('<vector'));
    expect(source, contains('<path'));
  });
}
