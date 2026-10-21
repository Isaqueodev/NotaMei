import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/export/csv_export.dart';
import 'package:notamei/export/export_screen.dart';
import 'package:notamei/export/export_gateway.dart';

import 'export_screen_test.dart' show MemoryRepository, reveal;

List<EntryRecord> fixture() => [
  EntryRecord(
    id: 'sale',
    type: EntryType.income,
    scope: EntryScope.business,
    amountCents: 100000,
    category: 'Venda',
    date: DateTime(2026, 10, 21),
  ),
  EntryRecord(
    id: 'cost',
    type: EntryType.expense,
    scope: EntryScope.business,
    amountCents: 20000,
    category: 'Material',
    date: DateTime(2026, 10, 21),
  ),
  for (final scope in EntryScope.values)
    EntryRecord(
      id: scope.name,
      withdrawalId: '=synthetic',
      type: scope == EntryScope.business ? EntryType.expense : EntryType.income,
      scope: scope,
      amountCents: 30000,
      category: 'Retirada do titular',
      date: DateTime(2026, 10, 21),
      note: '=sintético; "teste"\nlinha',
    ),
];
void main() {
  test('CSV identifica vínculo e natureza, explica filtros e totais internos separados', () async {
    final report = CsvReport.generate(
      fixture(),
      ExportSelection(
        anchor: DateTime(2026, 10),
        period: ExportPeriod.month,
        scope: null,
        includeNotes: true,
      ),
    );
    expect(report.csv, contains('"natureza"'));
    expect(report.csv, contains('"withdrawal_id"'));
    expect(report.csv, contains('"\t=synthetic"'));
    expect(report.csv, contains('"Retirada do titular"'));
    expect(report.csv, contains('"Transferências enviadas"'));
    expect(report.csv, contains('"Transferências recebidas"'));
    expect(
      report.csv,
      contains(
        'internas excluídas dos totais consolidados mesmo com filtro de tipo',
      ),
    );
    expect(report.sentCents, BigInt.from(30000));
    expect(report.receivedCents, BigInt.from(30000));
    expect(report.balanceCents, BigInt.from(80000));
    // Synthetic artifact only, parsed separately with Python's standard csv reader.
    await File('build/fb08-synthetic.csv').writeAsBytes(report.bytes);
  });
  testWidgets(
    'prévia distingue internas e coincide com CSV em Todos + só Saídas',
    (tester) async {
      final repo = MemoryRepository();
      repo.records.addAll(fixture());
      try {
        CsvReport? delivered;
        await tester.pumpWidget(
          MaterialApp(
            home: ExportScreen(
              repository: repo,
              initialDate: DateTime(2026, 10),
              save: (report) async {
                delivered = report;
                return ExportOutcome.saved;
              },
            ),
          ),
        );
        await reveal(tester, find.text('Balanço selecionado: R\$ 500,00'));
        expect(
          find.text('Transferências enviadas: R\$ 300,00'),
          findsOneWidget,
        );
        expect(find.text('Entradas selecionadas: R\$ 1000,00'), findsOneWidget);
        expect(find.text('Saídas selecionadas: R\$ 200,00'), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, 1600));
        await tester.pumpAndSettle();
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
        await reveal(tester, find.text('Balanço selecionado: R\$ -200,00'));
        expect(
          find.text('Transferências enviadas: R\$ 300,00'),
          findsOneWidget,
        );
        await reveal(tester, find.text('Salvar CSV'));
        await tester.tap(find.text('Salvar CSV'));
        await tester.pumpAndSettle();
        expect(delivered!.balanceCents, BigInt.from(-20000));
        expect(delivered!.sentCents, BigInt.from(30000));
        expect(delivered!.receivedCents, BigInt.zero);
        expect(delivered!.entries, hasLength(2));
        expect(delivered!.selection.includeNotes, isFalse);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        repo.dispose();
      }
    },
  );
}
