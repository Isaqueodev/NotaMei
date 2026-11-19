import 'dart:io';

import 'package:notamei/core/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/backup_import_plan.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

EntryRecord item(String id, {int cents = 100, String? note}) => EntryRecord(
  id: id,
  type: EntryType.income,
  scope: EntryScope.business,
  amountCents: cents,
  category: 'Serviços',
  date: DateTime(2026, 11, 18),
  note: note,
);
FinancialBackup backup(List<EntryRecord> entries) =>
    FinancialBackupCodec.decode(
      FinancialBackupCodec.encode(
        entries,
        createdAt: DateTime.utc(2026, 11, 18),
      ),
    );

class UnreadableRepository extends EntryRepository {
  UnreadableRepository()
    : super(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
  @override
  Future<void> initialize() async =>
      throw StateError('SEGREDO_FINANCEIRO caminho');
}

void main() {
  sqfliteFfiInit();
  late EntryRepository repository;
  setUp(() {
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() async {
    await repository.close();
    repository.dispose();
  });
  test('falha ao preparar prévia não expõe erro ou caminho da base', () async {
    final broken = UnreadableRepository();
    try {
      await broken.previewBackupImport(backup([]));
      fail('Esperado erro seguro');
    } catch (error) {
      expect(error, isA<BackupImportException>());
      expect(error.toString(), isNot(contains('SEGREDO_FINANCEIRO')));
    } finally {
      await broken.close();
      broken.dispose();
    }
  });
  test(
    'limites combinados de quantidade e bytes não truncam registros',
    () async {
      final existing = List.generate(10000, (i) => item('local-$i'));
      expect(
        () => BackupImportPlan.prepare(existing, backup([item('novo')])),
        throwsA(isA<BackupImportException>()),
      );
      final text = List.filled(5 * 1024 * 1024, 'x').join();
      expect(
        () => BackupImportPlan.prepare([
          item('local', note: text),
        ], backup([item('novo', note: text)])),
        throwsA(isA<BackupImportException>()),
      );
    },
  );
  test(
    'pareamento e oito campos preservados após importar e reimportar',
    () async {
      final source = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      try {
        await source.upsert(
          EntryRecord(
            id: 'pessoal',
            type: EntryType.expense,
            scope: EntryScope.personal,
            amountCents: 123,
            category: 'Categoria',
            date: DateTime.utc(2025, 12, 31, 23, 59),
            note: 'ação\nlinha',
          ),
        );
        await source.saveWithdrawal(
          operationId: 'integra',
          amountCents: 456,
          date: DateTime(2026, 1, 1),
          note: 'duas pontas',
        );
        final file = backup(source.entries);
        final plan = await repository.previewBackupImport(file);
        await repository.importBackup(plan);
        final result = await repository.previewBackupImport(file);
        expect(result.identicalCount, 3);
        expect(result.addedCount, 0);
        for (final record in file.entries) {
          expect(
            sameBackupRecord(
              record,
              repository.entries.singleWhere((e) => e.id == record.id),
            ),
            isTrue,
          );
        }
        await repository.importBackup(result);
        expect(repository.entries.length, 3);
      } finally {
        await source.close();
        source.dispose();
      }
    },
  );
  test('cada diferença de conteúdo é conflito, inclusive data local/UTC e nota vazia', () async {
    final base = item('igual');
    for (final changed in [
      EntryRecord(
        id: 'igual',
        type: EntryType.expense,
        scope: base.scope,
        amountCents: base.amountCents,
        category: base.category,
        date: base.date,
      ),
      EntryRecord(
        id: 'igual',
        type: base.type,
        scope: EntryScope.personal,
        amountCents: base.amountCents,
        category: base.category,
        date: base.date,
      ),
      EntryRecord(
        id: 'igual',
        type: base.type,
        scope: base.scope,
        amountCents: 101,
        category: base.category,
        date: base.date,
      ),
      EntryRecord(
        id: 'igual',
        type: base.type,
        scope: base.scope,
        amountCents: base.amountCents,
        category: 'Outro',
        date: base.date,
      ),
      EntryRecord(
        id: 'igual',
        type: base.type,
        scope: base.scope,
        amountCents: base.amountCents,
        category: base.category,
        date: DateTime.utc(2026, 11, 18),
      ),
      item('igual', note: ''),
    ]) {
      expect(
        BackupImportPlan.prepare([base], backup([changed])).conflictCount,
        1,
      );
    }
  });
  test(
    'prévia aguarda a fila e bloqueia repetição de um plano já aplicado',
    () async {
      final saving = repository.upsert(item('anterior'));
      final preview = repository.previewBackupImport(backup([item('novo')]));
      await saving;
      final plan = await preview;
      expect(plan.before.map((e) => e.id), ['anterior']);
      expect(() => plan.before.clear(), throwsUnsupportedError);
      expect(() => plan.additions.clear(), throwsUnsupportedError);
      await repository.importBackup(plan);
      await expectLater(
        repository.importBackup(plan),
        throwsA(
          isA<BackupImportException>().having(
            (e) => e.reason,
            'reason',
            BackupImportFailure.stale,
          ),
        ),
      );
    },
  );
  test(
    'alteração após prévia exige nova confirmação, sem gravação parcial',
    () async {
      final plan = await repository.previewBackupImport(
        backup([item('arquivo')]),
      );
      await repository.upsert(item('posterior'));
      await expectLater(
        repository.importBackup(plan),
        throwsA(
          isA<BackupImportException>().having(
            (e) => e.reason,
            'reason',
            BackupImportFailure.stale,
          ),
        ),
      );
      expect(repository.entries.map((e) => e.id), ['posterior']);
    },
  );
  test(
    'overflow dos totais combinados é rejeitado antes de importar',
    () async {
      await repository.upsert(item('maximo', cents: maxMoneyCents));
      await expectLater(
        repository.previewBackupImport(backup([item('extra')])),
        throwsA(isA<BackupImportException>()),
      );
      expect(repository.entries.single.id, 'maximo');
    },
  );
  test(
    'falha SQLite na segunda ponta reverte tudo e não expõe conteúdo',
    () async {
      final dir = await Directory(
        Platform.environment['TMPDIR'] ?? Directory.systemTemp.path,
      ).createTemp('backup-import-test-');
      addTearDown(() async {
        await repository.close();
        await dir.delete(recursive: true);
      });
      await repository.close();
      repository.dispose();
      final path = '${dir.path}/fixture.db';
      repository = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: path,
      );
      await repository.upsert(item('local'));
      final pair = [
        EntryRecord(
          id: 'withdrawal:par:business',
          type: EntryType.expense,
          scope: EntryScope.business,
          amountCents: 1,
          category: 'Retirada do titular',
          date: DateTime(2026, 11, 18),
          withdrawalId: 'par',
        ),
        EntryRecord(
          id: 'withdrawal:par:personal',
          type: EntryType.income,
          scope: EntryScope.personal,
          amountCents: 1,
          category: 'Retirada do titular',
          date: DateTime(2026, 11, 18),
          withdrawalId: 'par',
        ),
      ];
      final db = await databaseFactoryFfiNoIsolate.openDatabase(path);
      await db.execute(
        "CREATE TRIGGER fail_import BEFORE INSERT ON entries WHEN NEW.id = 'withdrawal:par:personal' BEGIN SELECT RAISE(ABORT, 'SEGREDO_FINANCEIRO'); END",
      );
      final plan = await repository.previewBackupImport(backup(pair));
      final before = repository.entries;
      var notifications = 0;
      repository.addListener(() => notifications++);
      try {
        await repository.importBackup(plan);
        fail('Era esperado rollback');
      } catch (e) {
        expect(e, isA<BackupImportException>());
        expect(e.toString(), isNot(contains('SEGREDO_FINANCEIRO')));
      }
      expect(identical(repository.entries, before), isTrue);
      expect(notifications, 0);
      expect(await db.query('entries'), hasLength(1));
      await db.execute('DROP TRIGGER fail_import');
      await repository.importBackup(plan);
      expect(repository.entries, hasLength(3));
      await repository.close();
      await repository.initialize();
      expect(repository.entries, hasLength(3));
      await repository.close();
    },
  );
  test(
    'reimportar ignora IDs idênticos sem notificação ou duplicação',
    () async {
      await repository.upsert(item('igual', note: 'texto'));
      final original = repository.entries;
      var notifications = 0;
      repository.addListener(() => notifications++);
      final plan = await repository.previewBackupImport(
        backup([item('igual', note: 'texto')]),
      );
      expect(plan.addedCount, 0);
      expect(plan.identicalCount, 1);
      expect(plan.conflictCount, 0);
      await repository.importBackup(plan);
      expect(repository.entries.length, 1);
      expect(notifications, 0);
      expect(repository.entries.single.note, original.single.note);
    },
  );
  test(
    'ID existente com conteúdo diferente bloqueia o arquivo inteiro',
    () async {
      await repository.upsert(item('colisao', note: 'local'));
      final before = repository.entries;
      final plan = await repository.previewBackupImport(
        backup([item('novo'), item('colisao', note: 'arquivo')]),
      );
      expect(plan.conflictCount, 1);
      await expectLater(
        repository.importBackup(plan),
        throwsA(isA<BackupImportException>()),
      );
      expect(identical(repository.entries, before), isTrue);
    },
  );
  test('prévia não escreve; confirmação adiciona sem apagar e notifica após commit', () async {
    await repository.upsert(item('local'));
    var notifications = 0;
    repository.addListener(() => notifications++);
    final plan = await repository.previewBackupImport(backup([item('novo')]));
    expect(plan.addedCount, 1);
    expect(repository.entries.map((e) => e.id), ['local']);
    expect(notifications, 0);
    final result = await repository.importBackup(plan);
    expect(result.addedCount, 1);
    expect(repository.entries.map((e) => e.id).toSet(), {'local', 'novo'});
    expect(notifications, 1);
  });
}
