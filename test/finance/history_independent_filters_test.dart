import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/finance/entry_history_screen.dart';
import 'package:notamei/theme/notamei_theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('Todos no âmbito preserva tipo e mantém seleção explícita', (
    tester,
  ) async {
    final repository = EntryRepository(
      databaseFactory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    await repository.initialize();
    for (final item in [
      (
        id: 'income',
        type: EntryType.income,
        scope: EntryScope.business,
        category: 'Receita exemplo',
      ),
      (
        id: 'business-expense',
        type: EntryType.expense,
        scope: EntryScope.business,
        category: 'Despesa comercial exemplo',
      ),
      (
        id: 'personal-expense',
        type: EntryType.expense,
        scope: EntryScope.personal,
        category: 'Despesa pessoal exemplo',
      ),
    ]) {
      await repository.upsert(
        EntryRecord(
          id: item.id,
          type: item.type,
          scope: item.scope,
          amountCents: 1000,
          category: item.category,
          date: DateTime.now(),
        ),
      );
    }
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: NotaMeiTheme.data,
          home: EntryHistoryScreen(repository: repository, onEdit: (_) {}),
        ),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Saídas'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Todos'))
            .selected,
        isTrue,
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Negócio'));
      await tester.pumpAndSettle();
      expect(find.text('1 registros'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Todos'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Saídas'))
            .selected,
        isTrue,
      );
      expect(find.text('2 registros'), findsOneWidget);
      expect(find.text('Receita exemplo'), findsNothing);
      expect(find.text('Despesa comercial exemplo'), findsOneWidget);
      expect(find.text('Despesa pessoal exemplo'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(repository.close);
      repository.dispose();
    }
  });
}
