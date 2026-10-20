import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/core/money.dart';
import 'package:notamei/annual/annual_summary.dart';

import 'notamei_finance_test.dart' show FlowApp;

import 'package:notamei/finance/entry_form_screen.dart';
import 'package:notamei/finance/dashboard_screen.dart';

void main() {
  sqfliteFfiInit();
  late EntryRepository repository;
  var closed = false;
  final now = DateTime.now();

  EntryRecord record(
    String id,
    int amount,
    EntryScope scope,
    EntryType type, {
    DateTime? date,
  }) => EntryRecord(
    id: id,
    amountCents: amount,
    scope: scope,
    type: type,
    category: id,
    date: date ?? DateTime(now.year, now.month, 10),
  );

  setUp(() async {
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    await repository.initialize();
    await repository.upsert(
      record('venda-negocio', 10000, EntryScope.business, EntryType.income),
    );
    await repository.upsert(
      record('custo-negocio', 2000, EntryScope.business, EntryType.expense),
    );
    await repository.upsert(
      record('entrada-pessoal', 5000, EntryScope.personal, EntryType.income),
    );
    await repository.upsert(
      record('gasto-pessoal', 1000, EntryScope.personal, EntryType.expense),
    );
    await repository.upsert(
      record(
        'pessoal-mes-anterior',
        20000,
        EntryScope.personal,
        EntryType.income,
        date: DateTime(now.year, now.month - 1, 10),
      ),
    );
    closed = false;
  });
  tearDown(() async {
    if (!closed) {
      await repository.close();
      repository.dispose();
    }
  });
  void dashboardTest(String name, WidgetTesterCallback body) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: DashboardScreen(
              repository: repository,
              onAdd: () {},
              onHistory: () {},
            ),
          ),
        );
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => repository.close());
        repository.dispose();
        closed = true;
      }
    });
  }

  dashboardTest(
    'Pessoal usa totais e recentes pessoais com identificação explícita',
    (tester) async {
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pessoal'));
      await tester.pumpAndSettle();
      expect(find.text('Balanço Pessoal (Mês)'), findsOneWidget);
      expect(find.text('Balanço do Negócio (Mês)'), findsNothing);
      expect(find.text('R\$ 40,00'), findsOneWidget);
      expect(find.text('entrada-pessoal'), findsOneWidget);
      expect(find.text('gasto-pessoal'), findsOneWidget);
      expect(find.text('venda-negocio'), findsNothing);
      expect(repository.summaryFor(now).incomeCents, 10000);
    },
  );

  dashboardTest(
    'Todos identifica a soma geral sem alterar os totais comerciais',
    (tester) async {
      await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Balanço geral (Mês)'), findsOneWidget);
      expect(
        find.text('Negócio + Pessoal. Total geral dos registros informados.'),
        findsOneWidget,
      );
      expect(find.text('R\$ 120,00'), findsOneWidget);
      expect(find.text('venda-negocio'), findsOneWidget);
      expect(find.text('entrada-pessoal'), findsOneWidget);
      expect(repository.summaryFor(now).balanceCents, 8000);
    },
  );

  dashboardTest(
    'estado vazio respeita o filtro Pessoal e mantém a seleção ao trocar o mês',
    (tester) async {
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pessoal'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pessoal'))
            .selected,
        isTrue,
      );
      expect(find.text('R\$ 0,00'), findsNWidgets(3));
      expect(
        find.textContaining('Nenhum lançamento pessoal neste mês.'),
        findsOneWidget,
      );
      expect(find.text('venda-negocio'), findsNothing);
      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.pumpAndSettle();
      expect(find.text('R\$ 200,00'), findsNWidgets(2));
      expect(find.text('pessoal-mes-anterior'), findsOneWidget);
    },
  );

  dashboardTest('filtros e cartões cabem na largura de um celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    for (final scope in ['Negócio', 'Pessoal', 'Todos']) {
      await tester.tap(find.widgetWithText(ChoiceChip, scope));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  dashboardTest(
    'totais acima do intervalo não derrubam o painel nem mostram soma parcial',
    (tester) async {
      await tester.runAsync(
        () => repository.upsert(
          record(
            'entrada-pessoal-limite',
            maxMoneyCents,
            EntryScope.personal,
            EntryType.income,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pessoal'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Os totais deste filtro excedem o intervalo suportado.'),
        findsOneWidget,
      );
      expect(find.text('—'), findsNWidgets(3));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Negócio'));
      await tester.pumpAndSettle();
      expect(find.text('R\$ 80,00'), findsOneWidget);
      expect(
        find.text('Os totais deste filtro excedem o intervalo suportado.'),
        findsNothing,
      );
    },
  );

  dashboardTest(
    'atualização do repositório mantém filtro e não muda o acompanhamento anual comercial',
    (tester) async {
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pessoal'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => repository.upsert(
          record(
            'nova-entrada-pessoal',
            1000,
            EntryScope.personal,
            EntryType.income,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pessoal'))
            .selected,
        isTrue,
      );
      expect(find.text('R\$ 50,00'), findsOneWidget);
      expect(find.text('nova-entrada-pessoal'), findsOneWidget);
      expect(
        recordedAnnualIncome(repository.entries, now.year).totalCents,
        10000,
      );
      await tester.runAsync(() => repository.remove('nova-entrada-pessoal'));
      await tester.pumpAndSettle();
      expect(find.text('R\$ 40,00'), findsOneWidget);
    },
  );

  dashboardTest('voltar do formulário preserva o filtro escolhido no Início', (
    tester,
  ) async {
    await tester.pumpWidget(FlowApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pessoal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Novo Lançamento'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryFormScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pessoal'))
          .selected,
      isTrue,
    );
    expect(find.text('R\$ 40,00'), findsOneWidget);
  });

  dashboardTest('Início inicia em Negócio e filtra também os recentes', (
    tester,
  ) async {
    expect(find.widgetWithText(ChoiceChip, 'Negócio'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Pessoal'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Todos'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Negócio'))
          .selected,
      isTrue,
    );
    expect(find.text('Balanço do Negócio (Mês)'), findsOneWidget);
    expect(find.text('R\$ 80,00'), findsOneWidget);
    expect(find.text('venda-negocio'), findsOneWidget);
    expect(find.text('entrada-pessoal'), findsNothing);
    expect(find.text('gasto-pessoal'), findsNothing);
  });
}
