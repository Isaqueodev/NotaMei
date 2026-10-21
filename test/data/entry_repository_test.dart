import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';

EntryRecord entry(
  String id, {
  EntryType type = EntryType.income,
  EntryScope scope = EntryScope.business,
  int amount = 10000,
  DateTime? date,
  String category = 'Serviços',
  String? note,
}) => EntryRecord(
  id: id,
  type: type,
  scope: scope,
  amountCents: amount,
  category: category,
  date: date ?? DateTime(2026, 10, 15),
  note: note,
);

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late EntryRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('notamei-test-');
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfi,
      path: '${directory.path}/entries.db',
    );
    await repository.initialize();
  });
  tearDown(() async {
    await repository.close();
    repository.dispose();
    await directory.delete(recursive: true);
  });
  test('SQLite persists all fields across repository restart', () async {
    final date = DateTime.utc(2026, 10, 31, 23, 59, 59, 123, 456);
    await repository.upsert(entry('a', date: date, note: 'Pix'));
    await repository.close();
    repository.dispose();
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfi,
      path: '${directory.path}/entries.db',
    );
    await repository.initialize();
    final saved = repository.entries.single;
    expect(saved.id, 'a');
    expect(saved.type, EntryType.income);
    expect(saved.scope, EntryScope.business);
    expect(saved.amountCents, 10000);
    expect(saved.category, 'Serviços');
    expect(saved.date, date);
    expect(saved.date.isUtc, true);
    expect(saved.note, 'Pix');
  });
  test('month business totals exclude personal and other months', () async {
    await repository.upsert(entry('income'));
    await repository.upsert(
      entry('expense', type: EntryType.expense, amount: 2500),
    );
    await repository.upsert(entry('personal', scope: EntryScope.personal));
    await repository.upsert(entry('old', date: DateTime(2025, 10)));
    await repository.upsert(entry('next', date: DateTime(2026, 11)));
    final summary = repository.summaryFor(DateTime(2026, 10));
    expect(summary.incomeCents, 10000);
    expect(summary.expenseCents, 2500);
    expect(summary.balanceCents, 7500);
    expect(repository.forMonth(DateTime(2026, 10)).length, 3);
    expect(repository.summaryFor(DateTime(2026, 12)).balanceCents, 0);
  });
  test(
    'rejeita novo registro se a soma mensal exceder inteiro de 64 bits',
    () async {
      const halfPlusOne = 4611686018427387904;
      await repository.upsert(entry('one', amount: halfPlusOne));
      await expectLater(
        repository.upsert(entry('two', amount: halfPlusOne)),
        throwsRangeError,
      );
      expect(repository.entries.length, 1);
      expect(
        repository.summaryFor(DateTime(2026, 10)).incomeCents,
        halfPlusOne,
      );
    },
  );
  test('rejeita soma anual acima do intervalo em meses diferentes', () async {
    const halfPlusOne = 4611686018427387904;
    await repository.upsert(entry('october', amount: halfPlusOne));
    await expectLater(
      repository.upsert(
        entry('november', amount: halfPlusOne, date: DateTime(2026, 11, 1)),
      ),
      throwsRangeError,
    );
    expect(repository.entries, hasLength(1));
  });
  test(
    'edit and delete refresh totals and notify without duplicates',
    () async {
      var notifications = 0;
      repository.addListener(() => notifications++);
      await repository.upsert(entry('a'));
      await repository.upsert(
        entry('a', type: EntryType.expense, amount: 200, category: 'Material'),
      );
      expect(repository.entries.length, 1);
      expect(repository.entries.single.note, isNull);
      expect(repository.summaryFor(DateTime(2026, 10)).balanceCents, -200);
      expect(() => repository.entries.clear(), throwsUnsupportedError);
      await repository.remove('a');
      expect(repository.entries, isEmpty);
      expect(repository.summaryFor(DateTime(2026, 10)).balanceCents, 0);
      expect(notifications, 3);
    },
  );
  test('edits and deletes survive reopening SQLite', () async {
    await repository.upsert(entry('edited', note: 'Original'));
    await repository.upsert(entry('deleted'));
    await repository.upsert(
      entry(
        'edited',
        type: EntryType.expense,
        scope: EntryScope.personal,
        amount: 123,
        category: 'Casa',
        date: DateTime(2026, 11, 1),
      ),
    );
    await repository.remove('deleted');
    await repository.close();
    await repository.initialize();
    final saved = repository.entries.single;
    expect(saved.id, 'edited');
    expect(saved.type, EntryType.expense);
    expect(saved.scope, EntryScope.personal);
    expect(saved.amountCents, 123);
    expect(saved.category, 'Casa');
    expect(saved.note, isNull);
    expect(repository.forMonth(DateTime(2026, 10)), isEmpty);
    expect(repository.summaryFor(DateTime(2026, 11)).balanceCents, 0);
  });
  test('SQLite schema has explicit version', () async {
    final db = await databaseFactoryFfi.openDatabase(
      '${directory.path}/entries.db',
    );
    expect(await db.getVersion(), 2);
  });
  test('invalid entries cannot enter domain', () {
    expect(() => entry('a', amount: 0), throwsArgumentError);
    expect(() => entry('a', amount: -1), throwsArgumentError);
    expect(() => entry('a', category: '  '), throwsArgumentError);
    expect(() => entry(''), throwsArgumentError);
  });
  test(
    'initialization is idempotent and concurrent writes are retained',
    () async {
      await Future.wait([repository.initialize(), repository.initialize()]);
      await Future.wait(
        List.generate(10, (i) => repository.upsert(entry('$i'))),
      );
      expect(repository.entries.length, 10);
    },
  );
}
