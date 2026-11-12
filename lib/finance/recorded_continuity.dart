import '../core/money.dart';
import '../data/entry_record.dart';
import '../data/entry_totals.dart';

/// Read-only continuity of informed records, by civil month and explicit scope.
/// No opening balance, synthetic entry, bank balance or profit is inferred.
class RecordedContinuity {
  RecordedContinuity.calculate(
    Iterable<EntryRecord> entries, {
    required DateTime month,
    required EntryScope? scope,
  }) {
    final selected = month.year * 12 + month.month;
    final eligible = entries
        .where((entry) {
          final period = entry.date.year * 12 + entry.date.month;
          return period <= selected && (scope == null || entry.scope == scope);
        })
        .toList(growable: false);
    final previous = eligible.where(
      (entry) => entry.date.year * 12 + entry.date.month < selected,
    );
    _previous = EntryTotals.calculate(previous, scope: scope).balanceCents;
    _accumulated = EntryTotals.calculate(eligible, scope: scope).balanceCents;
    DateTime? first;
    for (final entry in eligible) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (first == null || date.isBefore(first)) {
        first = date;
      }
    }
    firstRecordedDate = first;
  }

  late final BigInt _previous;
  late final BigInt _accumulated;
  late final DateTime? firstRecordedDate;

  // Bound each displayed result independently before converting to int.
  int? get previousCents => _checked(_previous);
  int? get accumulatedCents => _checked(_accumulated);

  static int? _checked(BigInt value) =>
      value.abs() <= BigInt.from(maxMoneyCents) ? value.toInt() : null;
}
