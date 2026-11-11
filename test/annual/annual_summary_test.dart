import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/annual/annual_summary.dart';
import 'package:notamei/core/money.dart';
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
          type: EntryType.income,
          scope: EntryScope.business,
          amountCents: 10000,
          category: 'Vendas',
          date: DateTime(2026, 2, 2),
        ),
        EntryRecord(
          id: 'business-expense',
          type: EntryType.expense,
          scope: EntryScope.business,
          amountCents: 345,
          category: 'Material',
          date: DateTime(2026, 1, 3),
        ),
        EntryRecord(
          id: 'personal',
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
        EntryRecord(
          id: 'next-year',
          type: EntryType.income,
          scope: EntryScope.business,
          amountCents: 1300,
          category: 'Vendas',
          date: DateTime(2027, 1, 1),
        ),
      ];
      final summary = recordedAnnualIncome(entries, 2026);
      expect(summary.totalCents, 22345);
      expect(summary.monthlyCents[1], 12345);
      expect(summary.monthlyCents[2], 10000);
    },
  );

  test('ano soma somente despesas comuns do negócio no ano civil', () {
    final expenses = [
      EntryRecord(
        id: 'business-jan',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 2500,
        category: 'Material',
        date: DateTime(2026, 1, 10),
      ),
      EntryRecord(
        id: 'business-feb',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 1000,
        category: 'Material',
        date: DateTime(2026, 2, 10),
      ),
      EntryRecord(
        id: 'withdrawal-out',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 3000,
        category: 'Retirada',
        date: DateTime(2026, 2, 11),
        withdrawalId: 'withdrawal-1',
      ),
      EntryRecord(
        id: 'withdrawal-in',
        type: EntryType.income,
        scope: EntryScope.personal,
        amountCents: 3000,
        category: 'Retirada',
        date: DateTime(2026, 2, 11),
        withdrawalId: 'withdrawal-1',
      ),
      EntryRecord(
        id: 'personal-expense',
        type: EntryType.expense,
        scope: EntryScope.personal,
        amountCents: 6000,
        category: 'Pessoal',
        date: DateTime(2026, 2, 12),
      ),
      EntryRecord(
        id: 'previous-year',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 700,
        category: 'Material',
        date: DateTime(2025, 12, 31),
      ),
    ];

    final summary = recordedAnnualExpenses(expenses, 2026);

    expect(summary.totalCents, 3500);
    expect(summary.monthlyCents[1], 2500);
    expect(summary.monthlyCents[2], 1000);
    expect(summary.monthlyCents[12], 0);
    expect(summary.monthlyCents, hasLength(12));
  });

  test('inclui dezembro no ano civil e exclui registros do ano seguinte', () {
    final expenses = [
      EntryRecord(
        id: 'december',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 400,
        category: 'Material',
        date: DateTime(2026, 12, 31),
      ),
      EntryRecord(
        id: 'next-year',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 1300,
        category: 'Material',
        date: DateTime(2027, 1, 1),
      ),
    ];

    final year2026 = recordedAnnualExpenses(expenses, 2026);
    final year2027 = recordedAnnualExpenses(expenses, 2027);

    expect(year2026.totalCents, 400);
    expect(year2026.monthlyCents[12], 400);
    expect(year2026.monthlyCents[1], 0);
    expect(year2027.totalCents, 1300);
    expect(year2027.monthlyCents[1], 1300);
  });

  test('overflow mensal torna indisponível o mês e o total anual', () {
    final summary = recordedAnnualExpenses([
      EntryRecord(
        id: 'max-month',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: maxMoneyCents,
        category: 'Material',
        date: DateTime(2026, 1, 1),
      ),
      EntryRecord(
        id: 'overflow-month',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 1,
        category: 'Material',
        date: DateTime(2026, 1, 2),
      ),
    ], 2026);

    expect(summary.totalCents, isNull);
    expect(summary.monthlyCents[1], isNull);
    expect(summary.monthlyCents[2], 0);
  });

  test('overflow anual preserva meses individualmente válidos', () {
    final summary = recordedAnnualExpenses([
      EntryRecord(
        id: 'max-year',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: maxMoneyCents,
        category: 'Material',
        date: DateTime(2026, 1, 1),
      ),
      EntryRecord(
        id: 'overflow-year',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 1,
        category: 'Material',
        date: DateTime(2026, 2, 1),
      ),
    ], 2026);

    expect(summary.totalCents, isNull);
    expect(summary.monthlyCents[1], maxMoneyCents);
    expect(summary.monthlyCents[2], 1);
  });
}
