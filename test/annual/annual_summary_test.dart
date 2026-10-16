import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/annual/annual_summary.dart';
import 'package:notamei/data/entry_record.dart';

void main() {
  test(
    'ano soma apenas entradas do negócio informadas, sem confundir com saldo',
    () {
      final entries = [
        EntryRecord(
          id: 'a',
          type: EntryType.income,
          scope: EntryScope.business,
          amountCents: 12345,
          category: 'Vendas',
          date: DateTime(2026, 1, 2),
        ),
        EntryRecord(
          id: 'b',
          type: EntryType.expense,
          scope: EntryScope.business,
          amountCents: 345,
          category: 'Material',
          date: DateTime(2026, 1, 3),
        ),
        EntryRecord(
          id: 'c',
          type: EntryType.income,
          scope: EntryScope.personal,
          amountCents: 99999,
          category: 'Pessoal',
          date: DateTime(2026, 1, 4),
        ),
        EntryRecord(
          id: 'd',
          type: EntryType.income,
          scope: EntryScope.business,
          amountCents: 900,
          category: 'Vendas',
          date: DateTime(2025, 12, 31),
        ),
      ];
      final summary = recordedAnnualIncome(entries, 2026);
      expect(summary.totalCents, 12345);
      expect(summary.monthlyCents[1], 12345);
      expect(summary.monthlyCents[2], 0);
    },
  );
}
