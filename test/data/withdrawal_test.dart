import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/data/entry_record.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late EntryRepository repo;
  setUp(() async {
    dir = await Directory(Platform.environment['TMPDIR']!).createTemp('fb08-');
    repo = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: '${dir.path}/test.db',
    );
    await repo.initialize();
  });
  tearDown(() async {
    await repo.close();
    repo.dispose();
    await dir.delete(recursive: true);
  });
  test(
    'mesma operação concorrente e exclusão em fila nunca publicam órfãos',
    () async {
      final sizes = <int>[];
      repo.addListener(() {
        sizes.add(repo.entries.length);
        expect(repo.entries.length.isEven, isTrue);
      });
      await Future.wait([
        repo.saveWithdrawal(
          operationId: 'serial',
          amountCents: 1,
          date: DateTime(2026),
        ),
        repo.saveWithdrawal(
          operationId: 'serial',
          amountCents: 2,
          date: DateTime(2026),
        ),
        repo.remove('withdrawal:serial:personal'),
      ]).timeout(const Duration(seconds: 5));
      expect(repo.entries, isEmpty);
      expect(sizes, [2, 2, 0]);
      await repo.saveWithdrawal(
        operationId: 'after',
        amountCents: 1,
        date: DateTime(2026),
      );
      expect(repo.entries, hasLength(2));
    },
  );
  test(
    'releitura falha após duas escritas reverte tudo e retry usa mesmo vínculo',
    () async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        '${dir.path}/test.db',
      );
      var notices = 0;
      repo.addListener(() => notices++);
      await db.execute(
        "CREATE TRIGGER fail_read AFTER INSERT ON entries WHEN NEW.scope = 'personal' BEGIN UPDATE entries SET date = 'invalid-date' WHERE id = NEW.id; END",
      );
      await expectLater(
        repo.saveWithdrawal(
          operationId: 'read-retry',
          amountCents: 100,
          date: DateTime(2026),
        ),
        throwsFormatException,
      );
      expect(await db.query('entries'), isEmpty);
      expect(repo.entries, isEmpty);
      expect(notices, 0);
      await db.execute('DROP TRIGGER fail_read');
      await repo.saveWithdrawal(
        operationId: 'read-retry',
        amountCents: 100,
        date: DateTime(2026),
      );
      expect(repo.entries, hasLength(2));
      expect(repo.entries.every((e) => e.withdrawalId == 'read-retry'), isTrue);
      expect(notices, 1);
    },
  );
  test('recusa retirada se totais de internas excedem intervalo, sem alteração parcial', () async {
    const half = 4611686018427387904;
    await repo.saveWithdrawal(
      operationId: 'large',
      amountCents: half,
      date: DateTime(2026, 10),
    );
    await expectLater(
      repo.saveWithdrawal(
        operationId: 'overflow',
        amountCents: half,
        date: DateTime(2026, 10),
      ),
      throwsRangeError,
    );
    expect(repo.entries, hasLength(2));
  });
  test('retirada não ocupa soma de despesa operacional e não exige balanço positivo', () async {
    const half = 4611686018427387904;
    await repo.saveWithdrawal(
      operationId: 'large',
      amountCents: half,
      date: DateTime(2026, 10),
    );
    await repo.upsert(
      EntryRecord(
        id: 'cost',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: half - 1,
        category: 'Gasto',
        date: DateTime(2026, 10),
      ),
    );
    expect(repo.summaryFor(DateTime(2026, 10)).expenseCents, half - 1);
    expect(
      repo.summaryFor(DateTime(2026, 10)).balanceCents,
      -9223372036854775807,
    );
  });
  test('edição preserva IDs, APIs comuns não podem desmembrar par', () async {
    await repo.saveWithdrawal(
      operationId: 'edit',
      amountCents: 10,
      date: DateTime(2026),
    );
    final ids = repo.entries.map((e) => e.id).toSet();
    final leg = repo.entries.first;
    await expectLater(repo.upsert(leg), throwsStateError);
    await expectLater(
      repo.upsert(
        EntryRecord(
          id: leg.id,
          type: leg.type,
          scope: leg.scope,
          amountCents: 1,
          category: 'Comum',
          date: leg.date,
        ),
      ),
      throwsStateError,
    );
    await repo.saveWithdrawal(
      operationId: 'edit',
      amountCents: 20,
      date: DateTime(2026, 11),
      note: 'Editada',
    );
    expect(repo.entries.map((e) => e.id).toSet(), ids);
    expect(
      repo.entries.every((e) => e.amountCents == 20 && e.note == 'Editada'),
      isTrue,
    );
    await repo.remove(leg.id);
    expect(repo.entries, isEmpty);
    await repo.close();
    await repo.initialize();
    expect(repo.entries, isEmpty);
  });
  test(
    'falha SQLite na segunda ponta reverte criação e edição sem notificar',
    () async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        '${dir.path}/test.db',
      );
      var notifications = 0;
      repo.addListener(() => notifications++);
      await db.execute(
        "CREATE TRIGGER fail_second BEFORE INSERT ON entries WHEN NEW.scope = 'personal' BEGIN SELECT RAISE(ABORT, 'second leg'); END",
      );
      await expectLater(
        repo.saveWithdrawal(
          operationId: 'fail',
          amountCents: 10,
          date: DateTime(2026),
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('entries'), isEmpty);
      expect(repo.entries, isEmpty);
      expect(notifications, 0);
      await db.execute('DROP TRIGGER fail_second');
      await repo.saveWithdrawal(
        operationId: 'fail',
        amountCents: 10,
        date: DateTime(2026),
      );
      await db.execute(
        "CREATE TRIGGER fail_edit BEFORE UPDATE ON entries WHEN NEW.scope = 'personal' BEGIN SELECT RAISE(ABORT, 'second edit'); END",
      );
      await expectLater(
        repo.saveWithdrawal(
          operationId: 'fail',
          amountCents: 20,
          date: DateTime(2026, 11),
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(repo.entries.every((e) => e.amountCents == 10), isTrue);
      expect(
        (await db.query('entries')).every((e) => e['amount_cents'] == 10),
        isTrue,
      );
      expect(notifications, 1);
      await db.execute('DROP TRIGGER fail_edit');
      await db.execute(
        "CREATE TRIGGER fail_delete BEFORE DELETE ON entries WHEN OLD.scope = 'personal' BEGIN SELECT RAISE(ABORT, 'second delete'); END",
      );
      await expectLater(
        repo.remove(repo.entries.first.id),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('entries'), hasLength(2));
      expect(repo.entries, hasLength(2));
      expect(notifications, 1);
    },
  );
  test(
    'concorrência e colisão recusada não sobrescrevem registro comum',
    () async {
      await Future.wait(
        List.generate(
          8,
          (i) => repo.saveWithdrawal(
            operationId: '$i',
            amountCents: 10,
            date: DateTime(2026),
          ),
        ),
      );
      expect(repo.entries, hasLength(16));
      await repo.upsert(
        EntryRecord(
          id: 'withdrawal:collision:personal',
          type: EntryType.income,
          scope: EntryScope.personal,
          amountCents: 50,
          category: 'Antigo',
          date: DateTime(2026),
        ),
      );
      await expectLater(
        repo.saveWithdrawal(
          operationId: 'collision',
          amountCents: 10,
          date: DateTime(2026),
        ),
        throwsStateError,
      );
      expect(repo.entries, hasLength(17));
      expect(
        repo.entries.singleWhere((e) => e.category == 'Antigo').amountCents,
        50,
      );
    },
  );
  test(
    'migração real v1 preserva registros, sem inferir vínculo por texto',
    () async {
      await repo.close();
      final path = '${dir.path}/v1.db';
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE entries (id TEXT PRIMARY KEY, type TEXT, scope TEXT, amount_cents INTEGER, category TEXT, date TEXT, note TEXT)',
            );
            await db.insert('entries', {
              'id': 'old',
              'type': 'expense',
              'scope': 'business',
              'amount_cents': 123,
              'category': 'Retirada do titular',
              'date': '2026-10-01T00:00:00.000',
              'note': 'Não inferir',
            });
            await db.execute('CREATE TABLE preferences (value TEXT)');
            await db.insert('preferences', {'value': 'preservar'});
          },
        ),
      );
      await db.close();
      repo.dispose();
      repo = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: path,
      );
      await repo.initialize();
      expect(repo.entries.single.id, 'old');
      expect(repo.entries.single.withdrawalId, isNull);
      expect(repo.entries.single.note, 'Não inferir');
      final migrated = await databaseFactoryFfiNoIsolate.openDatabase(path);
      expect(await migrated.getVersion(), 2);
      expect(
        (await migrated.query('preferences')).single['value'],
        'preservar',
      );
      await repo.saveWithdrawal(
        operationId: 'new',
        amountCents: 10,
        date: DateTime(2026),
      );
      expect(repo.entries, hasLength(3));
    },
  );
  test(
    'retirada cria par persistente e retry conserva IDs sem duplicar',
    () async {
      var notifications = 0;
      repo.addListener(() => notifications++);
      final date = DateTime(2026, 10, 21);
      await repo.saveWithdrawal(
        operationId: 'op',
        amountCents: 30000,
        date: date,
        note: 'Manual',
      );
      final ids = repo.entries.map((e) => e.id).toSet();
      expect(repo.entries, hasLength(2));
      expect(
        repo.entries.every(
          (e) =>
              e.withdrawalId == 'op' &&
              e.amountCents == 30000 &&
              e.date == date &&
              e.note == 'Manual',
        ),
        isTrue,
      );
      expect(
        repo.entries.where((e) => e.scope == EntryScope.business).single.type,
        EntryType.expense,
      );
      expect(
        repo.entries.where((e) => e.scope == EntryScope.personal).single.type,
        EntryType.income,
      );
      expect(notifications, 1);
      await repo.saveWithdrawal(
        operationId: 'op',
        amountCents: 30000,
        date: date,
        note: 'Manual',
      );
      expect(repo.entries.map((e) => e.id).toSet(), ids);
      await repo.close();
      await repo.initialize();
      expect(repo.entries.map((e) => e.id).toSet(), ids);
      expect(repo.entries.every((e) => e.withdrawalId == 'op'), isTrue);
    },
  );
}
