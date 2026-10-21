import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/export/csv_export.dart';

EntryRecord entry(
  String id,
  DateTime date, {
  EntryScope scope = EntryScope.business,
  EntryType type = EntryType.income,
  int cents = 12345,
  String category = 'Venda',
  String? note,
}) => EntryRecord(
  id: id,
  type: type,
  scope: scope,
  amountCents: cents,
  category: category,
  date: date,
  note: note,
);

void main() {
  test('neutraliza variantes, controles e delimitadores sem perder o texto original', () {
    final dangerous = [
      '=1+2";=1+2',
      '＝1',
      '＋1',
      '－1',
      '＠cmd',
      '\uFEFF  @cmd',
      '\rtexto',
      '\ntexto',
      '\ttexto',
      '  +1',
    ];
    for (final text in dangerous) {
      final original = entry(
        'id',
        DateTime(2026, 10, 1),
        category: text,
        note: text,
      );
      final report = CsvReport.generate(
        [original],
        ExportSelection(
          anchor: DateTime(2026, 10),
          period: ExportPeriod.month,
          includeNotes: true,
        ),
      );
      expect(report.csv, contains('"\t${text.replaceAll('"', '""')}"'));
      expect(original.category, text);
      expect(original.note, text);
      expect(report.csv, contains('"123,45"'));
    }
  });
  test('observações são opt-in e aspas, acentos e quebras continuam no mesmo campo', () {
    final records = [
      entry(
        'id',
        DateTime(2026, 10, 1),
        category: 'Serviço; "A"',
        note: 'ação\nsegunda linha',
      ),
    ];
    final hidden = CsvReport.generate(
      records,
      ExportSelection(anchor: DateTime(2026, 10), period: ExportPeriod.month),
    );
    final included = CsvReport.generate(
      records,
      ExportSelection(
        anchor: DateTime(2026, 10),
        period: ExportPeriod.month,
        includeNotes: true,
      ),
    );
    expect(hidden.csv, isNot(contains('observacao')));
    expect(hidden.csv, isNot(contains('segunda linha')));
    expect(included.csv, contains('"Serviço; ""A"""'));
    expect(included.csv, contains('"ação\nsegunda linha"'));
    expect(included.csv, endsWith('\r\n'));
  });
  test('todos os períodos e combinações de filtros preservam somas exatas', () {
    final records = [
      entry('i', DateTime(2026, 10, 20), cents: 9007199254740993),
      entry(
        'e',
        DateTime(2026, 10, 20),
        type: EntryType.expense,
        cents: 9007199254740995,
      ),
      entry(
        'p',
        DateTime(2026, 10, 20),
        scope: EntryScope.personal,
        cents: 9223372036854775807,
      ),
      entry(
        'q',
        DateTime(2026, 10, 20),
        scope: EntryScope.personal,
        type: EntryType.expense,
        cents: 7,
      ),
    ];
    for (final period in ExportPeriod.values) {
      for (final scope in <EntryScope?>[null, ...EntryScope.values]) {
        for (final type in <EntryType?>[null, ...EntryType.values]) {
          final report = CsvReport.generate(
            records,
            ExportSelection(
              anchor: DateTime(2026, 10, 20),
              period: period,
              scope: scope,
              type: type,
            ),
          );
          final expected = records.where(
            (e) =>
                (scope == null || e.scope == scope) &&
                (type == null || e.type == type),
          );
          expect(
            report.entries.map((e) => e.id).toSet(),
            expected.map((e) => e.id).toSet(),
          );
          expect(
            report.incomeCents,
            expected
                .where((e) => e.type == EntryType.income)
                .fold(BigInt.zero, (s, e) => s + BigInt.from(e.amountCents)),
          );
          expect(
            report.expenseCents,
            expected
                .where((e) => e.type == EntryType.expense)
                .fold(BigInt.zero, (s, e) => s + BigInt.from(e.amountCents)),
          );
          expect(report.csv, isNot(contains('observacao')));
        }
      }
    }
    final report = CsvReport.generate(
      records.take(2),
      ExportSelection(anchor: DateTime(2026, 10), period: ExportPeriod.month),
    );
    expect(report.csv, contains('"90071992547409,93"'));
    expect(report.csv, contains('"-0,02"'));
    expect(() => report.entries.clear(), throwsUnsupportedError);
  });
  test(
    'seleção vazia gera cabeçalho e resumo zero sem observações privadas',
    () {
      final report = CsvReport.generate([
        entry('a', DateTime(2025), note: 'PRIVADO'),
      ], ExportSelection(anchor: DateTime(2026), period: ExportPeriod.year));
      expect(report.entries, isEmpty);
      expect(report.balanceCents, BigInt.zero);
      expect(report.csv, isNot(contains('PRIVADO')));
      expect(report.filename, 'notamei_2026-01-01_2026-12-31.csv');
    },
  );
  test(
    'textos perigosos são neutralizados sem transformar dinheiro em texto',
    () {
      final report = CsvReport.generate(
        [
          entry(
            '=id',
            DateTime(2026, 10, 1),
            category: '  =HYPERLINK("x");ação',
            note: '\t@SUM(1)\r\nsegunda linha',
          ),
          entry('b', DateTime(2026, 10, 1), category: '+cmd'),
          entry('c', DateTime(2026, 10, 1), category: '-cmd'),
        ],
        ExportSelection(
          anchor: DateTime(2026, 10),
          period: ExportPeriod.month,
          includeNotes: true,
        ),
      );
      expect(report.csv, contains('"\t=id"'));
      expect(report.csv, contains('"\t  =HYPERLINK(""x"");ação"'));
      expect(report.csv, contains('"\t\t@SUM(1)\r\nsegunda linha"'));
      expect(report.csv, contains('"\t+cmd"'));
      expect(report.csv, contains('"\t-cmd"'));
      expect(report.csv, contains('"123,45"'));
      expect(report.bytes.take(3), [239, 187, 191]);
    },
  );
  test('dia, semana de segunda a domingo e ano respeitam limites civis', () {
    final day = ExportSelection(
      anchor: DateTime(2024, 2, 29, 20),
      period: ExportPeriod.day,
    );
    expect(day.start, DateTime(2024, 2, 29));
    expect(day.endExclusive, DateTime(2024, 3, 1));
    final week = ExportSelection(
      anchor: DateTime(2027, 1, 3),
      period: ExportPeriod.week,
    );
    expect(week.start, DateTime(2026, 12, 28));
    expect(week.endExclusive, DateTime(2027, 1, 4));
    final monday = ExportSelection(
      anchor: DateTime(2027, 1, 4),
      period: ExportPeriod.week,
    );
    expect(monday.start, DateTime(2027, 1, 4));
    final year = ExportSelection(
      anchor: DateTime(2024, 2, 29),
      period: ExportPeriod.year,
    );
    expect(year.start, DateTime(2024));
    expect(year.endExclusive, DateTime(2025));
  });
  test('mês seleciona datas civis e âmbito sem alterar a origem', () {
    final entries = [
      entry('fora', DateTime(2026, 9, 30)),
      entry('ultimo', DateTime(2026, 10, 31, 23, 59)),
      entry('pessoal', DateTime(2026, 10, 2), scope: EntryScope.personal),
      entry('primeiro', DateTime(2026, 10, 1)),
      entry('depois', DateTime(2026, 11, 1)),
    ];
    final selection = ExportSelection(
      anchor: DateTime(2026, 10, 20),
      period: ExportPeriod.month,
    );
    final report = CsvReport.generate(entries, selection);
    expect(report.entries.map((e) => e.id), ['primeiro', 'ultimo']);
    expect(report.incomeCents, BigInt.from(24690));
    expect(report.expenseCents, BigInt.zero);
    expect(report.balanceCents, BigInt.from(24690));
    expect(entries.first.id, 'fora');
    expect(selection.start, DateTime(2026, 10, 1));
    expect(selection.endExclusive, DateTime(2026, 11, 1));
    expect(report.csv, contains('"valor_brl"'));
    expect(report.csv, contains('"123,45"'));
    expect(report.csv, contains('"246,90"'));
    expect(report.csv, isNot(contains('"pessoal"')));
  });
}
