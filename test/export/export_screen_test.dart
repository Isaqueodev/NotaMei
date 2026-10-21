import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/data/entry_repository.dart';
import 'package:notamei/export/csv_export.dart';
import 'package:notamei/export/export_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:notamei/export/export_gateway.dart';

class MemoryRepository extends EntryRepository {
  MemoryRepository() : super(databaseFactory: databaseFactoryFfiNoIsolate);
  final List<EntryRecord> records = [];
  @override
  List<EntryRecord> get entries => List.unmodifiable(records);
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  late MemoryRepository repository;
  setUp(() {
    repository = MemoryRepository();
    repository.records.addAll([
      EntryRecord(
        id: 'a',
        type: EntryType.income,
        scope: EntryScope.business,
        amountCents: 12345,
        category: 'Venda',
        date: DateTime(2026, 10, 20),
        note: 'privado',
      ),
      EntryRecord(
        id: 'b',
        type: EntryType.expense,
        scope: EntryScope.personal,
        amountCents: 500,
        category: 'Casa',
        date: DateTime(2026, 10, 20),
      ),
    ]);
  });
  tearDown(() => repository.dispose());

  testWidgets(
    'cancelamento e falha não anunciam sucesso e permitem tentar de novo',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ExportScreen(
            repository: repository,
            initialDate: DateTime(2026, 10, 20),
            save: (_) async {
              calls++;
              if (calls == 1) return ExportOutcome.cancelled;
              if (calls == 2) throw StateError('private path');
              return ExportOutcome.saved;
            },
          ),
        ),
      );
      Future<void> save() async {
        await reveal(tester, find.text('Salvar CSV'));
        await tester.tap(find.text('Salvar CSV'));
        await tester.pumpAndSettle();
      }

      await save();
      expect(
        find.text('Exportação cancelada. Nenhum lançamento foi alterado.'),
        findsOneWidget,
      );
      await save();
      expect(find.textContaining('Não foi possível exportar'), findsOneWidget);
      expect(find.textContaining('private path'), findsNothing);
      await save();
      expect(find.text('CSV salvo no local escolhido.'), findsOneWidget);
    },
  );

  testWidgets('duplo toque é bloqueado durante exportação e retorno aguarda', (
    tester,
  ) async {
    final completion = Completer<ExportOutcome>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScreen(
          repository: repository,
          initialDate: DateTime(2026, 10, 20),
          save: (_) {
            calls++;
            return completion.future;
          },
        ),
      ),
    );
    await reveal(tester, find.text('Salvar CSV'));
    await tester.tap(find.text('Salvar CSV'));
    await tester.tap(find.text('Salvar CSV'));
    await tester.pump();
    expect(calls, 1);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar CSV'))
          .onPressed,
      isNull,
    );
    completion.complete(ExportOutcome.saved);
    await tester.pumpAndSettle();
    expect(find.text('CSV salvo no local escolhido.'), findsOneWidget);
  });

  testWidgets('seleção vazia desabilita exportação', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScreen(repository: repository, initialDate: DateTime(2025)),
      ),
    );
    await reveal(
      tester,
      find.textContaining('Nenhum lançamento neste intervalo'),
    );
    expect(
      find.textContaining('Nenhum lançamento neste intervalo'),
      findsOneWidget,
    );
    await reveal(tester, find.text('Salvar CSV'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar CSV'))
          .onPressed,
      isNull,
    );
    await reveal(tester, find.text('Compartilhar CSV'));
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Compartilhar CSV'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    '390px e texto 2x permitem filtrar e compartilhar seleção explícita',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      CsvReport? delivered;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ExportScreen(
            repository: repository,
            initialDate: DateTime(2026, 10, 20),
            share: (report) async {
              delivered = report;
              return ExportOutcome.shared;
            },
          ),
        ),
      );
      await reveal(tester, find.byKey(const Key('export-scope')));
      await tester.tap(find.byKey(const Key('export-scope')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos (Negócio + Pessoal)').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('export-type')));
      await tester.tap(find.byKey(const Key('export-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saídas').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Compartilhar CSV'));
      await tester.tap(find.text('Compartilhar CSV'));
      await tester.pumpAndSettle();
      expect(delivered!.entries.single.id, 'b');
      expect(delivered!.selection.type, EntryType.expense);
      expect(delivered!.selection.scope, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('prévia e salvar usam a mesma seleção sem alterar registros', (
    tester,
  ) async {
    CsvReport? delivered;
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScreen(
          repository: repository,
          initialDate: DateTime(2026, 10, 20),
          save: (report) async {
            delivered = report;
            return ExportOutcome.saved;
          },
        ),
      ),
    );
    await reveal(tester, find.textContaining('2026-10-01'));
    expect(find.textContaining('2026-10-01'), findsOneWidget);
    expect(find.text('1 lançamento(s) selecionado(s)'), findsOneWidget);
    await reveal(tester, find.text('Salvar CSV'));
    await tester.tap(find.text('Salvar CSV'));
    await tester.pumpAndSettle();
    expect(delivered!.entries.single.id, 'a');
    expect(delivered!.selection.includeNotes, isFalse);
    expect(find.text('CSV salvo no local escolhido.'), findsOneWidget);
    expect(repository.entries.length, 2);
  });
}
