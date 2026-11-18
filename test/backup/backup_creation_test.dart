import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/backup_creation_service.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/export/export_gateway.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

EntryRecord record(
  String id, {
  EntryScope scope = EntryScope.business,
  DateTime? date,
}) => EntryRecord(
  id: id,
  type: EntryType.income,
  scope: scope,
  amountCents: 12345,
  category: 'Serviços',
  date: date ?? DateTime(2026, 11, 18),
  note: 'Fictício',
);

class ControlledSnapshotRepository extends EntryRepository {
  ControlledSnapshotRepository()
    : super(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
  bool failRead = false;
  List<EntryRecord>? forcedSnapshot;

  @override
  Future<List<EntryRecord>> snapshotForBackup() async {
    if (failRead) throw StateError('SEGREDO_FINANCEIRO na leitura');
    return forcedSnapshot ?? await super.snapshotForBackup();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_file_dialog');
  sqfliteFfiInit();
  late EntryRepository repository;
  setUp(() {
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await repository.close();
    repository.dispose();
  });

  test(
    'arquivo sintético gravado em disco pode ser relido sem perda de campos',
    () async {
      await repository.upsert(
        record('negocio-outro-ano', date: DateTime(2025, 12, 31)),
      );
      await repository.upsert(record('pessoal', scope: EntryScope.personal));
      await repository.saveWithdrawal(
        operationId: 'par-sintetico',
        amountCents: 100,
        date: DateTime(2026, 11, 18),
        note: 'Ação\nDuas pontas',
      );
      final original = repository.entries;
      final directory = await Directory(
        Platform.environment['TMPDIR'] ?? Directory.systemTemp.path,
      ).createTemp('notamei-backup-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/backup-sintetico.json');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            await file.writeAsBytes(call.arguments['data'], flush: true);
            expect(
              await file.readAsBytes(),
              orderedEquals(call.arguments['data']),
            );
            return file.path;
          });
      final service = BackupCreationService(
        repository: repository,
        now: () => DateTime.utc(2026, 11, 18, 13),
      );
      expect(await service.save(), ExportOutcome.saved);
      final stored = await file.readAsBytes();
      final decoded = FinancialBackupCodec.decode(stored);
      Map<String, Object?> fields(EntryRecord entry) => {
        'id': entry.id,
        'type': entry.type.name,
        'scope': entry.scope.name,
        'amountCents': entry.amountCents,
        'category': entry.category,
        'date': entry.date.toIso8601String(),
        'note': entry.note,
        'withdrawalId': entry.withdrawalId,
      };
      expect(
        decoded.entries.map(fields).toList(),
        original.map(fields).toList(),
      );
      final evidenceRoot = Platform.environment['NOTAMEI_BACKUP_EVIDENCE_DIR'];
      if (evidenceRoot != null) {
        await File('$evidenceRoot/backup-sintetico.json')
            .writeAsBytes(stored, flush: true);
      }
    },
  );

  test(
    'snapshot permanece disponível após mutação anterior rejeitada',
    () async {
      await repository.upsert(record('preservado'));
      await expectLater(
        repository.upsert(
          EntryRecord(
            id: 'retirada-invalida',
            type: EntryType.income,
            scope: EntryScope.business,
            amountCents: 1,
            category: 'Inválido',
            date: DateTime(2026),
            withdrawalId: 'orfao',
          ),
        ),
        throwsStateError,
      );
      expect((await repository.snapshotForBackup()).map((entry) => entry.id), [
        'preservado',
      ]);
    },
  );

  test('falha de leitura ou validação não abre seletor, não expõe dados e permite retentar', () async {
    repository.dispose();
    final controlled = ControlledSnapshotRepository();
    repository = controlled;
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls++;
          return '/document/backup.json';
        });
    final service = BackupCreationService(repository: repository);
    for (final failRead in [true, false]) {
      controlled.failRead = failRead;
      controlled.forcedSnapshot = [record('duplicado'), record('duplicado')];
      for (final action in <Future<Object> Function()>[
        service.prepare,
        service.save,
      ]) {
        try {
          await action();
          fail('Preparação inválida foi aceita');
        } catch (error) {
          expect(
            error,
            isA<BackupCreationException>().having(
              (e) => e.reason,
              'reason',
              BackupCreationFailure.preparation,
            ),
          );
          expect(error.toString(), isNot(contains('SEGREDO_FINANCEIRO')));
          expect(error.toString(), isNot(contains('duplicado')));
        }
      }
    }
    expect(calls, 0);
    controlled.failRead = false;
    controlled.forcedSnapshot = null;
    expect(await service.save(), ExportOutcome.saved);
    expect(calls, 1);
  });

  test('cancelamento não vira sucesso e permite uma nova tentativa', () async {
    Object? result;
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls++;
          return result;
        });
    final service = BackupCreationService(repository: repository);
    expect(await service.save(), ExportOutcome.cancelled);
    result = '/document/backup.json';
    expect(await service.save(), ExportOutcome.saved);
    expect(calls, 2);
  });

  test('erro nativo não expõe dados e libera nova tentativa', () async {
    var failSave = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (failSave) {
            throw PlatformException(
              code: 'io',
              message: 'SEGREDO_FINANCEIRO',
              details: 'nota e caminho privado',
            );
          }
          return '/document/backup.json';
        });
    final service = BackupCreationService(repository: repository);
    try {
      await service.save();
      fail('Era esperado um erro de salvamento');
    } catch (error) {
      expect(
        error,
        isA<BackupCreationException>().having(
          (e) => e.reason,
          'reason',
          BackupCreationFailure.save,
        ),
      );
      expect(error.toString(), isNot(contains('SEGREDO_FINANCEIRO')));
      expect(error.toString(), isNot(contains('caminho privado')));
    }
    failSave = false;
    expect(await service.save(), ExportOutcome.saved);
  });

  test(
    'bloqueia salvamento repetido e congela bytes enquanto seletor está aberto',
    () async {
      await repository.upsert(record('antes'));
      final started = Completer<void>();
      final release = Completer<String?>();
      var calls = 0;
      List<String>? savedIds;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls++;
            final bytes = call.arguments['data'];
            if (!started.isCompleted) started.complete();
            final result = await release.future;
            savedIds = FinancialBackupCodec.decode(bytes).entries
                .map((e) => e.id)
                .toList();
            return result;
          });
      final service = BackupCreationService(repository: repository);
      final pending = service.save();
      await started.future.timeout(const Duration(seconds: 5));
      await repository.upsert(record('depois'));
      final repeated = service.save().then<Object>(
        (value) => value,
        onError: (Object error) => error,
      );
      release.complete('/document/backup.json');
      expect(await pending, ExportOutcome.saved);
      expect(
        await repeated,
        isA<BackupCreationException>().having(
          (e) => e.reason,
          'reason',
          BackupCreationFailure.busy,
        ),
      );
      expect(calls, 1);
      expect(savedIds, ['antes']);
      expect((await service.prepare()).bytes, isNotEmpty);
    },
  );

  test(
    'salvar envia JSON completo ao seletor local sem escrever na base',
    () async {
      await repository.upsert(
        record('outro-ano', date: DateTime(2025, 12, 31)),
      );
      await repository.upsert(record('pessoal', scope: EntryScope.personal));
      await repository.saveWithdrawal(
        operationId: 'par',
        amountCents: 100,
        date: DateTime(2026, 11, 18),
        note: 'Original',
      );
      final before = repository.entries;
      final created = DateTime.utc(2026, 11, 18, 13);
      var calls = 0;
      var notifications = 0;
      repository.addListener(() => notifications++);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls++;
            expect(call.method, 'saveFile');
            expect(
              call.arguments['fileName'],
              'NotaMei_backup_${created.microsecondsSinceEpoch}.json',
            );
            expect(call.arguments['mimeTypesFilter'], ['application/json']);
            expect(call.arguments['localOnly'], isTrue);
            final backup = FinancialBackupCodec.decode(call.arguments['data']);
            expect(backup.createdAt, created);
            expect(backup.entries.map((e) => e.id), before.map((e) => e.id));
            expect(backup.entries.where((e) => e.isWithdrawal), hasLength(2));
            return '/document/backup.json';
          });
      final service = BackupCreationService(
        repository: repository,
        now: () => created,
      );
      expect(await service.save(), ExportOutcome.saved);
      expect(calls, 1);
      expect(identical(repository.entries, before), isTrue);
      expect(notifications, 0);
    },
  );

  test(
    'snapshot aguarda gravações anteriores e exclui as enfileiradas depois',
    () async {
      var notifications = 0;
      repository.addListener(() => notifications++);
      final firstSave = repository.upsert(record('anterior'));
      final capture = repository.snapshotForBackup();
      final laterSave = repository.upsert(record('posterior'));
      await Future.wait([firstSave, laterSave]);
      final snapshot = await capture;
      expect(snapshot.map((entry) => entry.id), ['anterior']);
      expect(repository.entries.map((entry) => entry.id).toSet(), {
        'anterior',
        'posterior',
      });
      expect(notifications, 2);
      expect(() => snapshot.clear(), throwsUnsupportedError);
    },
  );

  test(
    'prepara histórico completo após a fila sem filtros e com bytes imutáveis',
    () async {
      final first = repository.upsert(
        record('outro-ano', date: DateTime(2025, 12, 31)),
      );
      final second = repository.upsert(
        record('pessoal', scope: EntryScope.personal),
      );
      final created = DateTime.utc(2026, 11, 18, 13);
      final service = BackupCreationService(
        repository: repository,
        now: () => created,
      );
      final preparing = service.prepare();
      await Future.wait([first, second]);
      final document = await preparing;
      final copy = FinancialBackupCodec.decode(document.bytes);
      expect(copy.entries.map((entry) => entry.id).toSet(), {
        'outro-ano',
        'pessoal',
      });
      expect(copy.createdAt, created);
      expect(document.mimeType, 'application/json');
      expect(
        document.filename,
        'NotaMei_backup_${created.microsecondsSinceEpoch}.json',
      );
      expect(() => document.bytes[0] = 0, throwsUnsupportedError);
    },
  );
}
