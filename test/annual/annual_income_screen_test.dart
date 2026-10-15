import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/annual/annual_income_screen.dart';
import 'package:notamei/data/entry_record.dart';

void main() {
  testWidgets(
    'apresenta apenas entradas informadas sem concluir situação fiscal',
    (tester) async {
      final records = [
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
          scope: EntryScope.personal,
          amountCents: 90000,
          category: 'Pessoal',
          date: DateTime(2026, 1, 3),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(home: AnnualIncomeScreen(entries: records, year: 2026)),
      );
      expect(find.text('Entradas informadas em 2026'), findsOneWidget);
      expect(find.text('R\$ 123,45'), findsWidgets);
      expect(find.text('R\$ 900,00'), findsNothing);
      expect(find.textContaining('histórico parcial'), findsOneWidget);
      expect(find.textContaining('não é uma apuração fiscal'), findsOneWidget);
      expect(find.textContaining('Sem entrada informada'), findsWidgets);
    },
  );

  testWidgets('mostra o mês de uma entrada futura incluída no total', (
    tester,
  ) async {
    final year = DateTime.now().year + 1;
    final records = [
      EntryRecord(
        id: 'future',
        type: EntryType.income,
        scope: EntryScope.business,
        amountCents: 2300,
        category: 'Vendas',
        date: DateTime(year, 1, 10),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: AnnualIncomeScreen(entries: records, year: year),
      ),
    );
    expect(find.text('R\$ 23,00'), findsWidgets);
    expect(find.text('Janeiro'), findsOneWidget);
  });
}
