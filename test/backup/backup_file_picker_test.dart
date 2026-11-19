import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/backup_file_picker.dart';
import 'package:notamei/backup/backup_inspection_service.dart';
import 'package:notamei/backup/financial_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('br.edu.notamei/backup');
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('seletor valida bytes recebidos e cancelamento não é sucesso', () async {
    Object? result;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'pickBackup');
          return result;
        });
    final picker = BackupFilePicker();
    expect(await picker.pick(), isNull);
    result = FinancialBackupCodec.encode(
      [],
      createdAt: DateTime.utc(2026, 11, 18),
    );
    expect((await picker.pick())!.recordCount, 0);
  });
  test(
    'arquivo inválido, resposta inesperada e erros nativos não expõem detalhes',
    () async {
      Object? result = Uint8List.fromList([1, 2, 3]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (result == null) {
              throw PlatformException(
                code: 'io',
                message: 'SEGREDO_FINANCEIRO',
              );
            }
            return result;
          });
      for (final value in [
        Uint8List.fromList([1, 2, 3]),
        'caminho privado',
        null,
      ]) {
        result = value;
        try {
          await BackupFilePicker().pick();
          fail('Deveria falhar');
        } catch (e) {
          expect(e, isA<BackupInspectionException>());
          expect(e.toString(), isNot(contains('SEGREDO_FINANCEIRO')));
        }
      }
    },
  );
  test('limite nativo é preservado como erro de tamanho', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async =>
              throw PlatformException(code: 'too_large', message: 'privado'),
        );
    await expectLater(
      BackupFilePicker().pick(),
      throwsA(
        isA<BackupInspectionException>().having(
          (e) => e.reason,
          'reason',
          BackupInspectionFailure.tooLarge,
        ),
      ),
    );
  });
}
