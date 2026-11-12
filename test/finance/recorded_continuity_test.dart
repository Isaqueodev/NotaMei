import 'package:flutter_test/flutter_test.dart';
import 'package:notamei/core/money.dart';
import 'package:notamei/data/entry_record.dart';
import 'package:notamei/finance/recorded_continuity.dart';

EntryRecord entry(
  String id,
  int cents,
  DateTime date, {
  EntryScope scope = EntryScope.business,
  EntryType type = EntryType.income,
  String? withdrawalId,
}) => EntryRecord(
  id: id,
  amountCents: cents,
  date: date,
  scope: scope,
  type: type,
  category: 'Fixture continuidade',
  withdrawalId: withdrawalId,
);

RecordedContinuity summary(
  List<EntryRecord> records,
  DateTime month, [
  EntryScope? scope = EntryScope.business,
]) => RecordedContinuity.calculate(records, month: month, scope: scope);

void main() {
  test(
    'vazio e meses anteriores ao primeiro registro não inferem saldo inicial',
    () {
      final records = [entry('futuro', 1, DateTime(2027, 2))];
      for (final scope in <EntryScope?>[null, ...EntryScope.values]) {
        for (final records in [<EntryRecord>[], records]) {
          final result = summary(records, DateTime(2027, 1), scope);
          expect(result.previousCents, 0);
          expect(result.accumulatedCents, 0);
          expect(result.firstRecordedDate, isNull);
        }
      }
    },
  );

  test('virada de ano preserva meses anteriores e exclui o futuro', () {
    final result = summary([
      entry('futuro', 99999, DateTime(2027, 2)),
      entry('atual', 4001, DateTime(2027, 1, 31), type: EntryType.expense),
      entry('anterior', 10002, DateTime(2026, 12, 31)),
    ], DateTime(2027, 1, 15));
    expect(result.previousCents, 10002);
    expect(result.accumulatedCents, 10002 - 4001);
    expect(result.firstRecordedDate, DateTime(2026, 12, 31));
  });

  test('meses sem movimento preservam valores negativos e centavos', () {
    final result = summary([
      entry('saida', 101, DateTime(2025, 12), type: EntryType.expense),
    ], DateTime(2027, 3));
    expect(result.previousCents, -101);
    expect(result.accumulatedCents, -101);
  });

  test('retirada reduz Negócio, aumenta Pessoal e não duplica Todos', () {
    final records = [
      entry('negocio', 10000, DateTime(2026, 12)),
      entry('pessoal', 5000, DateTime(2026, 12), scope: EntryScope.personal),
      entry(
        'enviada',
        2000,
        DateTime(2027, 1),
        type: EntryType.expense,
        withdrawalId: 'retirada',
      ),
      entry(
        'recebida',
        2000,
        DateTime(2027, 1),
        scope: EntryScope.personal,
        withdrawalId: 'retirada',
      ),
    ];
    final business = summary(records, DateTime(2027, 1));
    final personal = summary(records, DateTime(2027, 1), EntryScope.personal);
    final all = summary(records, DateTime(2027, 1), null);
    expect(business.accumulatedCents, 10000 - 2000);
    expect(personal.accumulatedCents, 5000 + 2000);
    expect(all.accumulatedCents, 10000 + 5000);
    expect(
      all.accumulatedCents,
      business.accumulatedCents! + personal.accumulatedCents!,
    );
    expect(all.previousCents, 10000 + 5000);
  });

  test(
    'data civil inclui todo o último dia, sem converter UTC para outro mês',
    () {
      final result = summary([
        entry('ultimo', 123, DateTime.utc(2027, 1, 31, 23, 59, 59)),
        entry('primeiro', 456, DateTime.utc(2027, 2, 1)),
      ], DateTime(2027, 1));
      expect(result.previousCents, 0);
      expect(result.accumulatedCents, 123);
      expect(result.firstRecordedDate, DateTime(2027, 1, 31));
    },
  );

  test(
    'overflow acumulado não altera valor anterior nem exibe soma parcial',
    () {
      final result = summary([
        entry('limite', maxMoneyCents, DateTime(2026, 12)),
        entry('mais', 1, DateTime(2027, 1)),
      ], DateTime(2027, 1));
      expect(result.previousCents, maxMoneyCents);
      expect(result.accumulatedCents, isNull);
    },
  );

  test(
    'saldo negativo além do limite fica indisponível, sem wrap de inteiro',
    () {
      final result = summary([
        entry(
          'limite',
          maxMoneyCents,
          DateTime(2026, 12),
          type: EntryType.expense,
        ),
        entry('mais', 1, DateTime(2027, 1), type: EntryType.expense),
      ], DateTime(2027, 1));
      expect(result.previousCents, -maxMoneyCents);
      expect(result.accumulatedCents, isNull);
    },
  );

  test('BigInt permite recuperação exata após anterior fora do intervalo', () {
    final result = summary([
      entry('limite', maxMoneyCents, DateTime(2026, 12)),
      entry('mais', 1, DateTime(2027, 1)),
      entry('menos', 1, DateTime(2027, 2), type: EntryType.expense),
    ], DateTime(2027, 2));
    expect(result.previousCents, isNull);
    expect(result.accumulatedCents, maxMoneyCents);
  });

  test('snapshot novo reflete edição de data, exclusão e primeiro registro por âmbito', () {
    final old = entry('antigo', 100, DateTime(2026, 12));
    final personal = entry(
      'pessoal',
      500,
      DateTime(2025, 1),
      scope: EntryScope.personal,
    );
    final records = [old, personal];
    expect(
      summary(records, DateTime(2027, 1)).firstRecordedDate,
      DateTime(2026, 12),
    );
    final edited = entry('antigo', 200, DateTime(2027, 2));
    expect(summary([edited, personal], DateTime(2027, 1)).accumulatedCents, 0);
    expect(summary([personal], DateTime(2027, 1), null).accumulatedCents, 500);
    expect(records, [old, personal]);
  });
}
