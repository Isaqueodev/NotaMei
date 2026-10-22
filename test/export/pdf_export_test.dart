import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/export/csv_export.dart';
import 'package:notamei/export/pdf_export.dart';

import 'withdrawal_csv_test.dart' show fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'não substitui símbolos sem glifo e ignora observações desmarcadas',
    () async {
      final sample = fixture().first;
      final records = [
        EntryRecord(
          id: 'unicode',
          type: sample.type,
          scope: sample.scope,
          amountCents: 1,
          category: 'Venda',
          date: sample.date,
          note: 'Entrega 🚀',
        ),
      ];
      final hidden = await buildPdfReport(
        CsvReport.generate(
          records,
          ExportSelection(anchor: sample.date, period: ExportPeriod.month),
        ),
      );
      expect(hidden.mimeType, 'application/pdf');
      await expectLater(
        buildPdfReport(
          CsvReport.generate(
            records,
            ExportSelection(
              anchor: sample.date,
              period: ExportPeriod.month,
              includeNotes: true,
            ),
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('símbolos'),
          ),
        ),
      );
    },
  );
  test(
    'PDF limita volume sem truncar silenciosamente nem carregar fontes',
    () async {
      final sample = fixture().first;
      final report = CsvReport.generate(
        List.generate(
          1001,
          (i) => EntryRecord(
            id: '$i',
            type: sample.type,
            scope: sample.scope,
            amountCents: 1,
            category: 'Venda',
            date: sample.date,
          ),
        ),
        ExportSelection(anchor: sample.date, period: ExportPeriod.month),
      );
      await expectLater(
        buildPdfReport(report),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('1.000'),
          ),
        ),
      );
    },
  );
  test('limite de texto só considera observações quando incluídas', () async {
    final sample = fixture().first;
    final records = [
      EntryRecord(
        id: 'long',
        type: sample.type,
        scope: sample.scope,
        amountCents: 1,
        category: 'Venda',
        date: sample.date,
        note: 'x' * 200001,
      ),
    ];
    final hidden = await buildPdfReport(
      CsvReport.generate(
        records,
        ExportSelection(anchor: sample.date, period: ExportPeriod.month),
      ),
    );
    expect(hidden.mimeType, 'application/pdf');
    await expectLater(
      buildPdfReport(
        CsvReport.generate(
          records,
          ExportSelection(
            anchor: sample.date,
            period: ExportPeriod.month,
            includeNotes: true,
          ),
        ),
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('texto'),
        ),
      ),
    );
  });
  test('gera observação extensa e seleção filtrada para parser independente', () async {
    final sample = fixture().first;
    final source = [
      EntryRecord(
        id: 'notes',
        type: sample.type,
        scope: sample.scope,
        amountCents: 123,
        category: 'Ação e café',
        date: sample.date,
        note:
            'PRIVADO_PDF <script>texto</script> ${'texto ' * 2000} FIM_DA_NOTA',
      ),
    ];
    final withNotes = await buildPdfReport(
      CsvReport.generate(
        source,
        ExportSelection(
          anchor: sample.date,
          period: ExportPeriod.month,
          includeNotes: true,
        ),
      ),
    );
    await File('build/pdf-notes-synthetic.pdf').writeAsBytes(withNotes.bytes);
    final withoutNotes = await buildPdfReport(
      CsvReport.generate(
        source,
        ExportSelection(anchor: sample.date, period: ExportPeriod.month),
      ),
    );
    await File('build/pdf-no-notes-synthetic.pdf')
        .writeAsBytes(withoutNotes.bytes);
    final filtered = await buildPdfReport(
      CsvReport.generate(
        fixture(),
        ExportSelection(
          anchor: sample.date,
          period: ExportPeriod.month,
          scope: null,
          type: EntryType.expense,
        ),
      ),
    );
    await File('build/pdf-filtered-synthetic.pdf').writeAsBytes(filtered.bytes);
  });
  test('pagina mais de vinte páginas sem perder lançamentos do fim', () async {
    final sample = fixture().first;
    final report = CsvReport.generate(
      List.generate(
        650,
        (i) => EntryRecord(
          id: 'record-$i',
          type: sample.type,
          scope: sample.scope,
          amountCents: 1,
          category: 'REGISTRO_${i.toString().padLeft(4, '0')}',
          date: sample.date,
        ),
      ),
      ExportSelection(anchor: sample.date, period: ExportPeriod.month),
    );
    final document = await buildPdfReport(report);
    expect(String.fromCharCodes(document.bytes.take(5)), '%PDF-');
    await File('build/pdf-many-synthetic.pdf').writeAsBytes(document.bytes);
  });
  test(
    'gera PDF real local da mesma seleção do CSV sem mudar registros',
    () async {
      final source = fixture();
      final report = CsvReport.generate(
        source,
        ExportSelection(
          anchor: DateTime(2026, 10),
          period: ExportPeriod.month,
          scope: null,
        ),
      );
      final document = await buildPdfReport(report);
      expect(document.mimeType, 'application/pdf');
      expect(document.filename, 'notamei_2026-10-01_2026-10-31.pdf');
      expect(String.fromCharCodes(document.bytes.take(5)), '%PDF-');
      expect(document.bytes.length, greaterThan(1000));
      expect(source, hasLength(4));
      expect(report.balanceCents, BigInt.from(80000));
      await File('build/pdf-basic-synthetic.pdf').writeAsBytes(document.bytes);
    },
  );
}
