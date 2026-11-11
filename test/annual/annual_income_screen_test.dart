import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/annual/annual_income_screen.dart';
import 'package:notamei/core/money.dart';
import 'package:notamei/data/entry_record.dart';

void main() {
  testWidgets(
    'Editorial anual inclui os doze meses e legenda sem comprovar inatividade',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: AnnualIncomeScreen(
            entries: const [],
            year: DateTime.now().year + 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('—: sem registro daquele tipo; movimento não confirmado'),
        findsOneWidget,
      );
      expect(find.textContaining('histórico parcial'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Dezembro'), 300);
      expect(find.text('Dezembro').hitTestable(), findsOneWidget);
      expect(find.text('Sem movimento'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
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
      expect(find.text('Acompanhamento anual de 2026'), findsOneWidget);
      expect(find.text('R\$ 123,45'), findsWidgets);
      expect(find.text('R\$ 900,00'), findsNothing);
      expect(find.textContaining('histórico parcial'), findsOneWidget);
      expect(find.textContaining('não é uma apuração fiscal'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Janeiro'), 250);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Entradas de Janeiro: R\$ 123,45',
        ),
        findsOneWidget,
      );
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

  testWidgets('exibe despesas mesmo quando não há entradas', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final expense = EntryRecord(
      id: 'only-expense',
      type: EntryType.expense,
      scope: EntryScope.business,
      amountCents: 2500,
      category: 'Material',
      date: DateTime(2026, 2, 10),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: AnnualIncomeScreen(entries: [expense], year: 2026),
      ),
    );

    expect(find.text('TOTAL DE DESPESAS · NEGÓCIO · 2026'), findsOneWidget);
    expect(find.textContaining('R\$ 25,00'), findsWidgets);
    expect(
      find.text('Nenhuma entrada ou despesa do negócio informada neste ano.'),
      findsNothing,
    );
    expect(find.text('Fevereiro'), findsOneWidget);
    expect(find.text('Despesas'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Fevereiro'), 250);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Despesas de Fevereiro: R\$ 25,00',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Fevereiro: sem entrada informada; movimento não confirmado',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recalcula o resumo quando o ano recebido muda', (tester) async {
    final records = [
      EntryRecord(
        id: 'expense-2026',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 1000,
        category: 'Material',
        date: DateTime(2026, 1, 2),
      ),
      EntryRecord(
        id: 'expense-2027',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 2000,
        category: 'Material',
        date: DateTime(2027, 1, 2),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: AnnualIncomeScreen(entries: records, year: 2026)),
    );
    expect(find.text('TOTAL DE DESPESAS · NEGÓCIO · 2026'), findsOneWidget);
    expect(find.textContaining('R\$ 10,00'), findsWidgets);
    expect(find.textContaining('R\$ 20,00'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(home: AnnualIncomeScreen(entries: records, year: 2027)),
    );
    expect(find.text('TOTAL DE DESPESAS · NEGÓCIO · 2027'), findsOneWidget);
    expect(find.textContaining('R\$ 10,00'), findsNothing);
    expect(find.textContaining('R\$ 20,00'), findsWidgets);
  });

  testWidgets('recalcula e atualiza o estado vazio quando os registros mudam', (
    tester,
  ) async {
    final expense = EntryRecord(
      id: 'editable-expense',
      type: EntryType.expense,
      scope: EntryScope.business,
      amountCents: 1000,
      category: 'Material',
      date: DateTime(2026, 1, 2),
    );

    await tester.pumpWidget(
      MaterialApp(home: AnnualIncomeScreen(entries: [expense], year: 2026)),
    );
    expect(find.textContaining('R\$ 10,00'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(home: AnnualIncomeScreen(entries: const [], year: 2026)),
    );
    expect(find.textContaining('R\$ 10,00'), findsNothing);
    expect(
      find.text('Nenhuma entrada ou despesa do negócio informada neste ano.'),
      findsOneWidget,
    );
  });

  testWidgets('avisa e não exibe soma parcial em overflow de despesas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final expenses = [
      EntryRecord(
        id: 'max',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: maxMoneyCents,
        category: 'Material',
        date: DateTime(2026, 1, 1),
      ),
      EntryRecord(
        id: 'overflow',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 1,
        category: 'Material',
        date: DateTime(2026, 1, 2),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(home: AnnualIncomeScreen(entries: expenses, year: 2026)),
    );

    expect(
      find.text(
        'Alguns valores de despesas estão indisponíveis por exceder o limite de soma.',
      ),
      findsOneWidget,
    );
    expect(find.text('Indisponível'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Janeiro'), 250);
    expect(find.text('Indisponível'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
