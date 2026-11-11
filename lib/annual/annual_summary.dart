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

/// Despesas manuais observadas; valores nulos indicam overflow indisponível.
class AnnualRecordedExpenses {
  const AnnualRecordedExpenses({
    required this.totalCents,
    required this.monthlyCents,
  });

  final int? totalCents;
  final Map<int, int?> monthlyCents;

  bool get hasOverflow =>
      totalCents == null || monthlyCents.values.any((cents) => cents == null);
}

AnnualRecordedExpenses recordedAnnualExpenses(
  Iterable<EntryRecord> entries,
  int year,
) {
  final monthly = <int, int?>{
    for (var month = 1; month <= 12; month++) month: 0,
  };
  for (final entry in entries) {
    if (entry.isWithdrawal ||
        entry.date.year != year ||
        entry.scope != EntryScope.business ||
        entry.type != EntryType.expense) {
      continue;
    }
    final month = entry.date.month;
    final current = monthly[month];
    if (current == null) continue;
    try {
      monthly[month] = checkedAddCents(current, entry.amountCents);
    } on RangeError {
      monthly[month] = null;
    }
  }

  var total = 0;
  var totalAvailable = true;
  for (final cents in monthly.values) {
    if (cents == null) {
      totalAvailable = false;
      break;
    }
    try {
      total = checkedAddCents(total, cents);
    } on RangeError {
      totalAvailable = false;
      break;
    }
  }

  return AnnualRecordedExpenses(
    totalCents: totalAvailable ? total : null,
    monthlyCents: Map.unmodifiable(monthly),
  );
}
