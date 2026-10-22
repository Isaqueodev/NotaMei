import 'dart:async';

import 'package:notamei/data/entry_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/export/export_screen.dart';
import 'package:notamei/export/export_gateway.dart';
import 'package:notamei/export/pdf_export.dart';

import 'export_screen_test.dart' show MemoryRepository, reveal;
import 'withdrawal_csv_test.dart' show fixture;

void main() {
  for (final format in ExportFormat.values) {
    testWidgets(
      '$format congela a prévia durante a saída e bloqueia duplo toque',
      (tester) async {
        final repo = MemoryRepository()..records.addAll(fixture());
        final done = Completer<ExportOutcome>();
        var calls = 0;
        final label = format == ExportFormat.pdf ? 'PDF' : 'CSV';
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: ExportScreen(
                repository: repo,
                initialDate: DateTime(2026, 10),
                format: format,
                save: (report) {
                  calls++;
                  expect(report.entries, hasLength(3));
                  return done.future;
                },
              ),
            ),
          );
          await reveal(tester, find.text('Salvar $label'));
          await tester.tap(find.text('Salvar $label'));
          await tester.tap(find.text('Salvar $label'));
          await tester.pump();
          expect(calls, 1);
          expect(
            tester.widget<PopScope>(find.byType(PopScope)).canPop,
            isFalse,
          );
          repo.records.add(
            EntryRecord(
              id: 'new',
              type: EntryType.income,
              scope: EntryScope.business,
              amountCents: 1,
              category: 'Novo',
              date: DateTime(2026, 10),
            ),
          );
          repo.notifyListeners();
          await tester.pump();
          await tester.drag(find.byType(ListView), const Offset(0, 1800));
          await tester.pump();
          await tester.scrollUntilVisible(
            find.textContaining('lançamento(s) selecionado(s)'),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('3 lançamento(s) selecionado(s)'), findsOneWidget);
          done.complete(ExportOutcome.saved);
          await tester.pumpAndSettle();
          expect(find.text('4 lançamento(s) selecionado(s)'), findsOneWidget);
        } finally {
          if (!done.isCompleted) done.complete(ExportOutcome.cancelled);
          await tester.pumpWidget(const SizedBox.shrink());
          repo.dispose();
        }
      },
    );
  }
  testWidgets('PDF usa a mesma prévia e distingue cancelar, falha e salvar', (
    tester,
  ) async {
    final repo = MemoryRepository()..records.addAll(fixture());
    addTearDown(repo.dispose);
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScreen(
          repository: repo,
          initialDate: DateTime(2026, 10),
          format: ExportFormat.pdf,
          save: (report) async {
            expect(report.balanceCents, BigInt.from(50000));
            expect(report.selection.includeNotes, isFalse);
            calls++;
            if (calls == 1) return ExportOutcome.cancelled;
            if (calls == 2) throw StateError('private path');
            return ExportOutcome.saved;
          },
        ),
      ),
    );
    expect(find.text('Exportar PDF'), findsOneWidget);
    await reveal(tester, find.text('Balanço selecionado: R\$ 500,00'));
    Future<void> save() async {
      await reveal(tester, find.text('Salvar PDF'));
      await tester.tap(find.text('Salvar PDF'));
      await tester.pumpAndSettle();
    }

    await save();
    expect(find.textContaining('Exportação cancelada'), findsOneWidget);
    await save();
    expect(find.textContaining('Não foi possível exportar'), findsOneWidget);
    expect(find.textContaining('private path'), findsNothing);
    await save();
    expect(find.text('PDF salvo no local escolhido.'), findsOneWidget);
    expect(repo.entries, hasLength(4));
  });

  testWidgets(
    'limite de PDF orienta a reduzir seleção sem expor erro técnico',
    (tester) async {
      final repo = MemoryRepository()..records.addAll(fixture());
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ExportScreen(
            repository: repo,
            initialDate: DateTime(2026, 10),
            format: ExportFormat.pdf,
            save: (_) async => throw const PdfExportLimitException(
              'Use um período menor para este PDF.',
            ),
          ),
        ),
      );
      await reveal(tester, find.text('Salvar PDF'));
      await tester.tap(find.text('Salvar PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Use um período menor para este PDF.'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    },
  );
  testWidgets('PDF sem registros desabilita salvar e compartilhar', (
    tester,
  ) async {
    final repo = MemoryRepository();
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScreen(repository: repo, format: ExportFormat.pdf),
      ),
    );
    await reveal(tester, find.text('Salvar PDF'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar PDF'))
          .onPressed,
      isNull,
    );
    await reveal(tester, find.text('Compartilhar PDF'));
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Compartilhar PDF'),
          )
          .onPressed,
      isNull,
    );
  });
}
