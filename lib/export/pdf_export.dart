import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/entry_record.dart';
import 'csv_export.dart';
import 'export_document.dart';

const maxPdfRecords = 1000;
const maxPdfTextUnits = 200000;

class PdfExportLimitException implements Exception {
  const PdfExportLimitException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Uses the same immutable selection and exact totals as the CSV preview.
/// Assets are local; generation never touches the financial repository.
Future<ExportDocument> buildPdfReport(CsvReport report) async {
  if (report.entries.length > maxPdfRecords) {
    throw const PdfExportLimitException(
      'O PDF permite até 1.000 lançamentos por arquivo. Selecione um período menor ou use CSV.',
    );
  }
  var textUnits = 0;
  for (final entry in report.entries) {
    textUnits +=
        entry.category.length +
        (entry.withdrawalId?.length ?? 0) +
        (report.selection.includeNotes ? (entry.note?.length ?? 0) : 0);
    if (textUnits > maxPdfTextUnits) {
      throw const PdfExportLimitException(
        'O PDF inclui texto extenso demais. Reduza o período, desative observações ou use CSV.',
      );
    }
  }
  final font = await rootBundle.load('assets/fonts/Inter.ttf');
  final logo = await rootBundle.load('assets/brand/notamei.png');
  final bytes = await Isolate.run(() => _render(report, font, logo));
  return ExportDocument(
    bytes: bytes,
    filename: report.filename.replaceFirst(RegExp(r'\.csv$'), '.pdf'),
    mimeType: 'application/pdf',
  );
}

/// Bounded, separate text widgets let even a single long note span pages.
/// Break on whitespace where possible; very long tokens are broken, not dropped.
Iterable<String> _chunks(String text) sync* {
  for (final line
      in text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
    final runes = line.runes.toList();
    if (runes.isEmpty) {
      yield '';
      continue;
    }
    var start = 0;
    while (start < runes.length) {
      var end = (start + 160).clamp(0, runes.length);
      if (end < runes.length) {
        var split = end;
        while (split > start &&
            runes[split - 1] != 32 &&
            runes[split - 1] != 9) {
          split--;
        }
        end = split > start ? split : (start + 48).clamp(0, runes.length);
      }
      yield String.fromCharCodes(runes.sublist(start, end));
      start = end;
    }
  }
}

Future<Uint8List> _render(
  CsvReport report,
  ByteData fontData,
  ByteData logoData,
) async {
  final font = pw.Font.ttf(fontData);
  final logo = pw.MemoryImage(
    logoData.buffer.asUint8List(logoData.offsetInBytes, logoData.lengthInBytes),
  );
  final doc = pw.Document(
    title: 'NotaMei — Relatório de registros',
    author: 'NotaMei',
    creator: 'NotaMei',
  );
  final pdfFont = font.getFont(pw.Context(document: doc.document));
  for (final entry in report.entries) {
    final fields = [
      entry.category,
      entry.withdrawalId ?? '',
      if (report.selection.includeNotes) entry.note ?? '',
    ];
    for (final field in fields) {
      for (final rune in field.runes) {
        if (rune != 9 &&
            rune != 10 &&
            rune != 13 &&
            !pdfFont.isRuneSupported(rune)) {
          throw const PdfExportLimitException(
            'Há símbolos que a fonte do PDF não suporta. Desative observações quando aplicável ou use CSV para preservar o texto.',
          );
        }
      }
    }
  }
  final ink = PdfColor.fromHex('#1E1735');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          children: [
            pw.Image(logo, width: 28, height: 28),
            pw.SizedBox(width: 10),
            pw.Text(
              'NotaMei — Relatório de registros',
              style: pw.TextStyle(fontSize: 15, color: ink),
            ),
          ],
        ),
      ),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount} · Não é documento fiscal nem backup.',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (_) => [
        pw.Text(
          'Período: ${exportDate(report.selection.start)} a ${exportDate(report.lastDate)} (inclusive)',
        ),
        pw.Text(
          '${report.selection.scopeLabel} · ${report.selection.typeLabel}',
        ),
        pw.Text('${report.entries.length} lançamento(s) selecionado(s)'),
        pw.Text(
          report.selection.includeNotes
              ? 'Observações incluídas por escolha da pessoa.'
              : 'Observações não incluídas.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 12),
        for (final total in [
          ('Entradas', report.incomeCents),
          ('Saídas', report.expenseCents),
          ('Transferências enviadas', report.sentCents),
          ('Transferências recebidas', report.receivedCents),
          ('Balanço dos registros selecionados', report.balanceCents),
        ])
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Text('${total.$1}: R\$ ${exportAmount(total.$2)}'),
          ),
        pw.SizedBox(height: 8),
        pw.Text(
          report.summaryExplanation,
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 16),
        for (final entry in report.entries) ...[
          pw.Text(
            '${exportDate(entry.date)} · ${entry.type == EntryType.income ? 'Entrada' : 'Saída'} · ${entry.scope == EntryScope.business ? 'Negócio' : 'Pessoal'} · R\$ ${exportAmount(BigInt.from(entry.amountCents))}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          for (final chunk in _chunks('Categoria: ${entry.category}'))
            pw.Text(chunk, style: const pw.TextStyle(fontSize: 9)),
          if (entry.isWithdrawal) ...[
            pw.Text(
              'Retirada do titular · Negócio → Pessoal',
              style: const pw.TextStyle(fontSize: 9),
            ),
            for (final chunk in _chunks('Vínculo: ${entry.withdrawalId}'))
              pw.Text(chunk, style: const pw.TextStyle(fontSize: 9)),
          ],
          if (report.selection.includeNotes && entry.note != null)
            for (final chunk in _chunks('Observação: ${entry.note}'))
              pw.Text(chunk, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
        ],
      ],
    ),
  );
  return doc.save();
}
