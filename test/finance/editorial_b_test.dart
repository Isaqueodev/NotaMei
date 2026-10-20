import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/finance/dashboard_screen.dart';
import 'package:notamei/finance/entry_history_screen.dart';
import 'package:notamei/finance/entry_form_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late EntryRepository repository;
  setUp(() async {
    repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    await repository.initialize();
    await repository.upsert(
      EntryRecord(
        id: 'income',
        type: EntryType.income,
        scope: EntryScope.business,
        amountCents: 320000,
        category: 'Serviços Prestados',
        date: DateTime.now(),
      ),
    );
    await repository.upsert(
      EntryRecord(
        id: 'expense',
        type: EntryType.expense,
        scope: EntryScope.business,
        amountCents: 146000,
        category: 'Mercadorias / Matéria-prima',
        date: DateTime.now(),
        note: 'Registro manual de exemplo',
      ),
    );
  });

  testWidgets(
    'Início 390px com texto 2x mantém todos os âmbitos e valores sem cortes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: NotaMeiTheme.data,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: DashboardScreen(
              repository: repository,
              onAdd: () {},
              onHistory: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final scope in ['Negócio', 'Pessoal', 'Todos']) {
          await tester.scrollUntilVisible(
            find.widgetWithText(ChoiceChip, scope),
            -300,
          );
          await tester.tap(find.widgetWithText(ChoiceChip, scope));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, scope))
                .selected,
            isTrue,
          );
          await tester.scrollUntilVisible(find.text('Novo Lançamento'), 250);
          expect(find.text('Novo Lançamento').hitTestable(), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text(
              'Registros manuais e locais. Balanço = entradas menos saídas registradas.',
            ),
            300,
          );
          expect(tester.takeException(), isNull);
        }
        expect(find.text('- R\$ 1.460,00'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('- R\$ 1.460,00')).style!.overflow,
          isNot(TextOverflow.ellipsis),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => repository.close());
        repository.dispose();
      }
    },
  );

  testWidgets(
    'Formulário editorial tem seleção acessível e ações acima do teclado com texto ampliado',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: NotaMeiTheme.data,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: EntryFormScreen(repository: repository, onSaved: () {}),
          ),
        );
        await tester.pumpAndSettle();
        final income = find.widgetWithText(ChoiceChip, 'Receita (Entrada)');
        expect(income, findsOneWidget);
        expect(tester.widget<ChoiceChip>(income).selected, isTrue);
        await tester.tap(find.widgetWithText(ChoiceChip, 'Despesa (Saída)'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Despesa (Saída)'),
              )
              .selected,
          isTrue,
        );
        expect(find.text('Adicionar Lançamento').hitTestable(), findsOneWidget);
        expect(
          find.text('Salvar e adicionar outro').hitTestable(),
          findsOneWidget,
        );
        expect(
          tester.getBottomLeft(find.text('Salvar e adicionar outro')).dy,
          lessThanOrEqualTo(544),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => repository.close());
        repository.dispose();
      }
    },
  );

  testWidgets(
    'Histórico editorial separa filtros e mantém edição em 390px com texto 2x',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      EntryRecord? edited;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: NotaMeiTheme.data,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: EntryHistoryScreen(
              repository: repository,
              onEdit: (entry) => edited = entry,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Âmbito'), findsOneWidget);
        expect(find.text('Tipo'), findsOneWidget);
        expect(find.byKey(const Key('history-ledger')), findsOneWidget);
        await tester.ensureVisible(find.widgetWithText(FilterChip, 'Saídas'));
        await tester.tap(find.widgetWithText(FilterChip, 'Saídas'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Saídas'))
              .selected,
          isTrue,
        );
        expect(find.text('Serviços Prestados'), findsNothing);
        await tester.ensureVisible(find.text('Mercadorias / Matéria-prima'));
        await tester.tap(find.text('Mercadorias / Matéria-prima'));
        expect(edited?.id, 'expense');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => repository.close());
        repository.dispose();
      }
    },
  );

  testWidgets('Editorial B coloca ação após resumo e antes da folha, sem FAB', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var added = false;
    var history = false;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.data,
          home: DashboardScreen(
            repository: repository,
            onAdd: () => added = true,
            onHistory: () => history = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      final action = find.widgetWithText(ElevatedButton, 'Novo Lançamento');
      expect(action, findsOneWidget);
      expect(
        tester.getTopLeft(action).dy,
        greaterThan(
          tester.getBottomLeft(find.text('Balanço do Negócio (Mês)')).dy,
        ),
      );
      expect(
        tester.getBottomLeft(action).dy,
        lessThan(tester.getTopLeft(find.text('Lançamentos Recentes')).dy),
      );
      final summary = tester.widget<Container>(
        find.byKey(const Key('monthly-summary')),
      );
      final decoration = summary.decoration! as BoxDecoration;
      expect(decoration.color, NotaMeiTheme.ink);
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, isNull);
      expect(
        tester.widget<Text>(find.text('R\$ 3.200,00')).style!.color,
        NotaMeiTheme.incomeDark,
      );
      expect(
        tester.widget<Text>(find.text('R\$ 1.460,00')).style!.color,
        NotaMeiTheme.expenseDark,
      );
      expect(find.byKey(const Key('recent-ledger')), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(action);
      expect(added, isTrue);
      await tester.ensureVisible(find.text('Ver todos'));
      await tester.tap(find.text('Ver todos'));
      expect(history, isTrue);
      await tester.ensureVisible(find.text('Serviços Prestados'));
      final categoryPosition = tester.getTopLeft(
        find.text('Serviços Prestados'),
      );
      final amountPosition = tester.getTopLeft(find.text('+ R\$ 3.200,00'));
      expect(amountPosition.dx, greaterThan(categoryPosition.dx));
      expect(amountPosition.dy, closeTo(categoryPosition.dy, 1));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => repository.close());
      repository.dispose();
    }
  });
}
