import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/annual/annual_summary.dart';
import 'package:notamei/export/csv_export.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test(
    'exemplo em centavos: internas não inflam resumos nem anual; filtros civis',
    () async {
      final repo = EntryRepository(
        databaseFactory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      await repo.initialize();
      try {
        for (final spec in [
          ('venda', EntryType.income, EntryScope.business, 100000),
          ('gasto', EntryType.expense, EntryScope.business, 20000),
        ]) {
          await repo.upsert(
            EntryRecord(
              id: spec.$1,
              type: spec.$2,
              scope: spec.$3,
              amountCents: spec.$4,
              category: spec.$1,
              date: DateTime(2026, 10),
            ),
          );
        }
        await repo.saveWithdrawal(
          operationId: 'op',
          amountCents: 30000,
          date: DateTime(2026, 10),
        );
        final summary = repo.summaryFor(DateTime(2026, 10));
        expect(summary.incomeCents, 100000);
        expect(summary.expenseCents, 20000);
        expect(summary.balanceCents, 50000);
        expect(recordedAnnualIncome(repo.entries, 2026).totalCents, 100000);
        CsvReport report(
          EntryScope? scope, [
          EntryType? type,
          int month = 10,
        ]) => CsvReport.generate(
          repo.entries,
          ExportSelection(
            anchor: DateTime(2026, month),
            period: ExportPeriod.month,
            scope: scope,
            type: type,
          ),
        );
        expect(report(EntryScope.business).balanceCents, BigInt.from(50000));
        expect(report(EntryScope.personal).balanceCents, BigInt.from(30000));
        expect(report(null).incomeCents, BigInt.from(100000));
        expect(report(null).expenseCents, BigInt.from(20000));
        expect(report(null).balanceCents, BigInt.from(80000));
        expect(
          report(null, EntryType.income).balanceCents,
          BigInt.from(100000),
        );
        expect(
          report(null, EntryType.expense).balanceCents,
          BigInt.from(-20000),
        );
        await repo.upsert(
          EntryRecord(
            id: 'pessoal',
            type: EntryType.expense,
            scope: EntryScope.personal,
            amountCents: 1000,
            category: 'Casa',
            date: DateTime(2026, 10),
          ),
        );
        expect(report(EntryScope.personal).balanceCents, BigInt.from(29000));
        expect(report(null).balanceCents, BigInt.from(79000));
        await repo.saveWithdrawal(
          operationId: 'op',
          amountCents: 30000,
          date: DateTime(2026, 11),
        );
        expect(report(EntryScope.business).balanceCents, BigInt.from(80000));
        expect(report(EntryScope.personal).balanceCents, BigInt.from(-1000));
        expect(
          report(EntryScope.business, null, 11).balanceCents,
          BigInt.from(-30000),
        );
        expect(
          report(EntryScope.personal, null, 11).balanceCents,
          BigInt.from(30000),
        );
        expect(report(null, null, 11).balanceCents, BigInt.zero);
      } finally {
        await repo.close();
        repo.dispose();
      }
    },
  );
}
