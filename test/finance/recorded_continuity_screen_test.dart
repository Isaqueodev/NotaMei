import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:notamei/core/money.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/finance/dashboard_screen.dart';

EntryRecord record(
  String id,
  int cents,
  DateTime date, {
  EntryType type = EntryType.income,
  EntryScope scope = EntryScope.business,
}) => EntryRecord(
  id: id,
  type: type,
  scope: scope,
  amountCents: cents,
  category: id,
  date: date,
);

void main() {
  sqfliteFfiInit();
  late EntryRepository repository;
  final now = DateTime.now();
  setUp(() async {
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    await repository.initialize();
    await repository.upsert(
      record('antes', 10000, DateTime(now.year, now.month - 1, 10)),
    );
    await repository.upsert(
      record(
        'mes',
        2500,
        DateTime(now.year, now.month, 10),
        type: EntryType.expense,
      ),
    );
    await repository.upsert(
      record('futuro', 99900, DateTime(now.year, now.month + 1, 1)),
    );
  });

  void dashboardTest(
    String name,
    WidgetTesterCallback body, {
    Size size = const Size(800, 1400),
    double scale = 1,
  }) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
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
        await tester.runAsync(repository.close);
        repository.dispose();
      }
    });
  }

  Future<void> expand(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Continuidade entre meses'), 180);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuidade entre meses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuidade entre meses'));
    await tester.pumpAndSettle();
  }

  String? amount(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data;

  dashboardTest('filtros recalculam o acumulado sem misturar âmbitos', (
    tester,
  ) async {
    await tester.runAsync(
      () => repository.upsert(
        record(
          'pessoal',
          5000,
          DateTime(now.year, now.month - 1, 1),
          scope: EntryScope.personal,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expand(tester);
    expect(amount(tester, 'continuity-accumulated'), 'R\$ 75,00');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pessoal'));
    await tester.pumpAndSettle();
    expect(amount(tester, 'continuity-accumulated'), 'R\$ 50,00');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    expect(amount(tester, 'continuity-accumulated'), 'R\$ 125,00');
  });

  dashboardTest(
    'edição e exclusão retroativas atualizam sem recriar lançamentos',
    (tester) async {
      await expand(tester);
      await tester.runAsync(
        () => repository.upsert(
          record('antes', 20000, DateTime(now.year, now.month - 1, 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(amount(tester, 'continuity-previous'), 'R\$ 200,00');
      expect(amount(tester, 'continuity-accumulated'), 'R\$ 175,00');
      await tester.runAsync(
        () => repository.upsert(
          record('antes', 20000, DateTime(now.year, now.month + 1, 10)),
        ),
      );
      await tester.pumpAndSettle();
      expect(amount(tester, 'continuity-previous'), 'R\$ 0,00');
      expect(amount(tester, 'continuity-accumulated'), '-R\$ 25,00');
      await tester.runAsync(() => repository.remove('mes'));
      await tester.pumpAndSettle();
      expect(amount(tester, 'continuity-accumulated'), 'R\$ 0,00');
      expect(
        find.text('Sem registros neste âmbito até o mês selecionado.'),
        findsOneWidget,
      );
      expect(repository.entries.length, 2);
    },
  );

  dashboardTest('mês vazio carrega acumulado e preserva balanço mensal zero', (
    tester,
  ) async {
    await tester.runAsync(() => repository.remove('futuro'));
    await tester.pumpAndSettle();
    await expand(tester);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(amount(tester, 'continuity-previous'), 'R\$ 75,00');
    expect(amount(tester, 'continuity-accumulated'), 'R\$ 75,00');
    expect(
      find.descendant(
        of: find.byKey(const Key('monthly-summary')),
        matching: find.text('R\$ 0,00'),
      ),
      findsWidgets,
    );
  });

  dashboardTest('retirada recalcula os dois âmbitos sem alterar Todos', (
    tester,
  ) async {
    await tester.runAsync(
      () => repository.saveWithdrawal(
        operationId: 'teste-continuidade',
        amountCents: 2000,
        date: DateTime(now.year, now.month, 15),
      ),
    );
    await tester.pumpAndSettle();
    await expand(tester);
    expect(amount(tester, 'continuity-accumulated'), 'R\$ 55,00');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pessoal'));
    await tester.pumpAndSettle();
    expect(amount(tester, 'continuity-accumulated'), 'R\$ 20,00');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    expect(amount(tester, 'continuity-accumulated'), 'R\$ 75,00');
  });

  dashboardTest(
    'continuidade expandida cabe em celular com fonte ampliada',
    (tester) async {
      await expand(tester);
      await tester.ensureVisible(
        find.byKey(const Key('continuity-accumulated')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    size: const Size(320, 640),
    scale: 2,
  );

  dashboardTest('overflow acumulado não esconde o balanço mensal válido', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repository.remove('antes');
      await repository.upsert(
        record('limite-anterior', maxMoneyCents, DateTime(now.year - 1, 1)),
      );
      await repository.upsert(
        record('mais', 3000, DateTime(now.year, now.month, 20)),
      );
    });
    await tester.pumpAndSettle();
    await expand(tester);
    expect(amount(tester, 'continuity-previous'), formatMoney(maxMoneyCents));
    expect(amount(tester, 'continuity-accumulated'), '—');
    expect(
      find.text('Valor acumulado indisponível: excede o intervalo suportado.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('monthly-summary')),
        matching: find.text('R\$ 5,00'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'continuidade separada preserva o balanço do mês e exclui futuro',
    (tester) async {
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
        expect(find.text('Continuidade entre meses'), findsOneWidget);
        await tester.tap(find.text('Continuidade entre meses'));
        await tester.pumpAndSettle();
        final card = find.byKey(const Key('recorded-continuity'));
        expect(
          find.descendant(of: card, matching: find.text('Até o mês anterior')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('R\$ 100,00')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('R\$ 75,00')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('monthly-summary')),
            matching: find.text('-R\$ 25,00'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(repository.entries.length, 3);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(repository.close);
        repository.dispose();
      }
    },
  );
}
