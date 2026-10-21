import '../core/money.dart';
import '../data/entry_record.dart';

/// Entradas manuais observadas, sem pretensão de apuração fiscal oficial.
class AnnualRecordedIncome {
  const AnnualRecordedIncome({
    required this.totalCents,
    required this.monthlyCents,
  });

  final int totalCents;
  final Map<int, int> monthlyCents;
}

AnnualRecordedIncome recordedAnnualIncome(
  Iterable<EntryRecord> entries,
  int year,
) {
  final monthly = {for (var month = 1; month <= 12; month++) month: 0};
  for (final entry in entries) {
    if (entry.isWithdrawal ||
        entry.date.year != year ||
        entry.scope != EntryScope.business ||
        entry.type != EntryType.income) {
      continue;
    }
    monthly[entry.date.month] = checkedAddCents(
      monthly[entry.date.month]!,
      entry.amountCents,
    );
  }
  return AnnualRecordedIncome(
    totalCents: monthly.values.fold(0, checkedAddCents),
    monthlyCents: Map.unmodifiable(monthly),
  );
}
