import 'dart:convert';
import 'dart:typed_data';

import '../data/entry_record.dart';

enum ExportPeriod { day, week, month, year }

/// Calendar selection normalized to the recorded date, without its time.
class ExportSelection {
  ExportSelection({
    required DateTime anchor,
    required this.period,
    this.scope = EntryScope.business,
    this.type,
    this.includeNotes = false,
  }) : anchor = DateTime(anchor.year, anchor.month, anchor.day);

  final DateTime anchor;
  final ExportPeriod period;
  final EntryScope? scope;
  final EntryType? type;
  final bool includeNotes;

  DateTime get start => switch (period) {
    ExportPeriod.day => anchor,
    ExportPeriod.week => DateTime(
      anchor.year,
      anchor.month,
      anchor.day - (anchor.weekday - DateTime.monday),
    ),
    ExportPeriod.month => DateTime(anchor.year, anchor.month),
    ExportPeriod.year => DateTime(anchor.year),
  };
  DateTime get endExclusive => switch (period) {
    ExportPeriod.day => DateTime(start.year, start.month, start.day + 1),
    ExportPeriod.week => DateTime(start.year, start.month, start.day + 7),
    ExportPeriod.month => DateTime(start.year, start.month + 1),
    ExportPeriod.year => DateTime(start.year + 1),
  };
  String get scopeLabel => scope == null
      ? 'Todos (Negócio + Pessoal)'
      : scope == EntryScope.business
      ? 'Negócio'
      : 'Pessoal';
  String get typeLabel => type == null
      ? 'Entradas e saídas'
      : type == EntryType.income
      ? 'Entradas'
      : 'Saídas';
}

String _safeText(String text) {
  // Quoting alone does not prevent spreadsheet formula execution.
  // Prefix dangerous user text with TAB for spreadsheet viewing. TAB remains
  // in the exported data; consumers that strip it must reapply sanitization.
  // No strategy guarantees safety across all spreadsheet applications.
  final dangerous =
      RegExp(r'^[\s\x00-\x20\uFEFF]*[=+\-@＝＋－＠]').hasMatch(text) ||
      RegExp(r'^[\t\r\n]').hasMatch(text);
  return dangerous ? "\t$text" : text;
}

String exportDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String exportAmount(BigInt cents) {
  final absolute = cents.abs();
  return '${cents.isNegative ? '-' : ''}${absolute ~/ BigInt.from(100)},${(absolute % BigInt.from(100)).toString().padLeft(2, '0')}';
}

class CsvReport {
  CsvReport._(
    this.selection,
    this.entries,
    this.incomeCents,
    this.expenseCents,
  );

  factory CsvReport.generate(
    Iterable<EntryRecord> source,
    ExportSelection selection,
  ) {
    final entries =
        source.where((entry) {
          final date = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          return !date.isBefore(selection.start) &&
              date.isBefore(selection.endExclusive) &&
              (selection.scope == null || entry.scope == selection.scope) &&
              (selection.type == null || entry.type == selection.type);
        }).toList()..sort((a, b) {
          final comparison = exportDate(a.date).compareTo(exportDate(b.date));
          return comparison != 0 ? comparison : a.id.compareTo(b.id);
        });
    var income = BigInt.zero;
    var expense = BigInt.zero;
    for (final entry in entries) {
      if (entry.type == EntryType.income) {
        income += BigInt.from(entry.amountCents);
      } else {
        expense += BigInt.from(entry.amountCents);
      }
    }
    return CsvReport._(selection, List.unmodifiable(entries), income, expense);
  }

  final ExportSelection selection;
  final List<EntryRecord> entries;
  final BigInt incomeCents;
  final BigInt expenseCents;
  BigInt get balanceCents => incomeCents - expenseCents;
  DateTime get lastDate => DateTime(
    selection.endExclusive.year,
    selection.endExclusive.month,
    selection.endExclusive.day - 1,
  );
  String get filename =>
      'notamei_${exportDate(selection.start)}_${exportDate(lastDate)}.csv';
  Uint8List get bytes => Uint8List.fromList(utf8.encode('\uFEFF$csv'));

  String get csv {
    final metadata = [
      exportDate(selection.start),
      exportDate(lastDate),
      selection.scopeLabel,
      selection.typeLabel,
    ];
    final rows = <List<String>>[
      [
        'secao',
        'periodo_inicio',
        'periodo_fim',
        'filtro_ambito',
        'filtro_tipo',
        'id',
        'data',
        'tipo',
        'ambito',
        'valor_brl',
        'categoria',
        if (selection.includeNotes) 'observacao',
      ],
      for (final entry in entries)
        [
          'Lancamento',
          ...metadata,
          _safeText(entry.id),
          exportDate(entry.date),
          entry.type == EntryType.income ? 'Entrada' : 'Saída',
          entry.scope == EntryScope.business ? 'Negócio' : 'Pessoal',
          exportAmount(BigInt.from(entry.amountCents)),
          _safeText(entry.category),
          if (selection.includeNotes) _safeText(entry.note ?? ''),
        ],
      for (final total in [
        ('Entradas', incomeCents),
        ('Saídas', expenseCents),
        ('Balanço dos registros selecionados', balanceCents),
      ])
        [
          'Resumo',
          ...metadata,
          '',
          '',
          total.$1,
          selection.scopeLabel,
          exportAmount(total.$2),
          '',
          if (selection.includeNotes) '',
        ],
    ];
    return '${rows.map((row) => row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(';')).join('\r\n')}\r\n';
  }
}
