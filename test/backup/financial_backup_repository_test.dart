import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/backup/financial_backup.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/data/entry_totals.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

List<BigInt> totals(List<EntryRecord> entries, EntryScope? scope) {
  final result = EntryTotals.calculate(entries, scope: scope);
  return [
    result.incomeCents,
    result.expenseCents,
    result.receivedCents,
    result.sentCents,
    result.balanceCents,
  ];
}

void main() {
  sqfliteFfiInit();

  test('snapshot SQLite de todo histórico preserva campos e totais sem escrever na base', () async {
    final repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    addTearDown(() async {
      await repository.close();
      repository.dispose();
    });
    await repository.initialize();
    await repository.upsert(
      EntryRecord(
        id: 'negocio-ano-anterior',
        type: EntryType.income,
        scope: EntryScope.business,
        amountCents: 120000,
        category: 'Serviços',
        date: DateTime(2025, 12, 31),
        note: 'Nota original\n=1+1',
      ),
    );
    await repository.upsert(
      EntryRecord(
        id: 'pessoal-outro-mes',
        type: EntryType.expense,
        scope: EntryScope.personal,
        amountCents: 3456,
        category: 'Pessoal',
        date: DateTime.utc(2026, 1, 31, 23, 59),
        note: '',
      ),
    );
    await repository.saveWithdrawal(
      operationId: 'retirada-sintetica',
      amountCents: 12345,
      date: DateTime(2026, 11, 18),
      note: 'Duas pontas',
    );
    final before = repository.entries;
    final original = before.map(fields).toList();
    var notifications = 0;
    repository.addListener(() => notifications++);
    final bytes = FinancialBackupCodec.encode(
      before,
      createdAt: DateTime.utc(2026, 11, 18),
    );
    final backup = FinancialBackupCodec.decode(bytes);
    expect(backup.entries.map(fields).toList(), original);
    for (final scope in <EntryScope?>[null, ...EntryScope.values]) {
      expect(totals(backup.entries, scope), totals(before, scope));
    }
    final malformed = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    malformed['entries'][0]['amountCents'] = '0';
    expect(
      () => FinancialBackupCodec.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(malformed))),
      ),
      throwsFormatException,
    );
    expect(identical(repository.entries, before), isTrue);
    expect(repository.entries.map(fields).toList(), original);
    expect(notifications, 0);
  });
}
