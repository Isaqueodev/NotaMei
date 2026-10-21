import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/export/csv_export.dart';
import 'package:notamei/export/export_gateway.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_file_dialog');
  final report = CsvReport.generate([
    EntryRecord(
      id: 'a',
      type: EntryType.income,
      scope: EntryScope.business,
      amountCents: 123,
      category: 'ação',
      date: DateTime(2026, 10),
    ),
  ], ExportSelection(anchor: DateTime(2026, 10), period: ExportPeriod.month));
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('salvar envia bytes exatos ao seletor local, distingue cancelamento e propaga erro', () async {
    Object? result = 'content://documents/a';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'saveFile');
          expect(call.arguments['data'], report.bytes);
          expect(call.arguments['fileName'], report.filename);
          expect(call.arguments['localOnly'], isTrue);
          if (result is Exception) throw result;
          return result;
        });
    final gateway = ExportGateway();
    expect(await gateway.save(report), ExportOutcome.saved);
    result = null;
    expect(await gateway.save(report), ExportOutcome.cancelled);
    result = PlatformException(code: 'io');
    await expectLater(gateway.save(report), throwsA(isA<PlatformException>()));
  });

  test('compartilhar envia um CSV com nome, MIME e bytes corretos', () async {
    var status = ShareResultStatus.success;
    final gateway = ExportGateway(
      shareFile: (params) async {
        expect(params.fileNameOverrides, [report.filename]);
        expect(params.files, hasLength(1));
        expect(params.files!.single.mimeType, 'text/csv');
        expect(await params.files!.single.readAsBytes(), report.bytes);
        return ShareResult('test', status);
      },
    );
    expect(await gateway.share(report), ExportOutcome.shared);
    status = ShareResultStatus.dismissed;
    expect(await gateway.share(report), ExportOutcome.cancelled);
    status = ShareResultStatus.unavailable;
    expect(await gateway.share(report), ExportOutcome.unconfirmed);
  });
}
