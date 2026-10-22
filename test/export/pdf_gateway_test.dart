import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/export/export_document.dart';
import 'package:notamei/export/export_gateway.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_file_dialog');
  final bytes = Uint8List.fromList('%PDF-test'.codeUnits);
  final document = ExportDocument(
    bytes: bytes,
    filename: 'notamei_test.pdf',
    mimeType: 'application/pdf',
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('documento faz cópia imutável dos bytes', () {
    bytes[0] = 0;
    expect(document.bytes.first, '%'.codeUnitAt(0));
    expect(() => document.bytes[0] = 0, throwsUnsupportedError);
  });
  test(
    'salvar PDF envia nome, MIME e bytes exatos e trata cancelamento',
    () async {
      Object? answer = 'content://test.pdf';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.arguments['mimeTypesFilter'], ['application/pdf']);
            expect(call.arguments['fileName'], document.filename);
            expect(call.arguments['localOnly'], isTrue);
            expect(call.arguments['data'], document.bytes);
            if (answer is Exception) throw answer;
            return answer;
          });
      final gateway = ExportGateway();
      expect(await gateway.saveDocument(document), ExportOutcome.saved);
      answer = null;
      expect(await gateway.saveDocument(document), ExportOutcome.cancelled);
      answer = PlatformException(code: 'io');
      await expectLater(
        gateway.saveDocument(document),
        throwsA(isA<PlatformException>()),
      );
    },
  );
  test('compartilhar PDF preserva MIME e não presume transmissão', () async {
    var status = ShareResultStatus.success;
    final gateway = ExportGateway(
      shareFile: (params) async {
        expect(params.fileNameOverrides, [document.filename]);
        expect(params.files!.single.mimeType, 'application/pdf');
        expect(await params.files!.single.readAsBytes(), document.bytes);
        return ShareResult('test', status);
      },
    );
    expect(await gateway.shareDocument(document), ExportOutcome.shared);
    status = ShareResultStatus.dismissed;
    expect(await gateway.shareDocument(document), ExportOutcome.cancelled);
    status = ShareResultStatus.unavailable;
    expect(await gateway.shareDocument(document), ExportOutcome.unconfirmed);
  });
}
