import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fonte local do PDF está declarada e carregável no bundle', () async {
    const fontPath = 'assets/fonts/Inter.ttf';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    expect(manifest.listAssets(), contains(fontPath));
    final font = await rootBundle.load(fontPath);
    expect(font.lengthInBytes, greaterThan(0));
  });
}
