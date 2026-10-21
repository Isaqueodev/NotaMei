import '../core/money.dart';
import 'entry_record.dart';

/// Exact totals for an already selected period/type. Scope remains explicit:
/// internal legs never affect consolidated balance, even with one type only.
class EntryTotals {
  EntryTotals.calculate(
    Iterable<EntryRecord> entries, {
    required EntryScope? scope,
  }) {
    for (final entry in entries) {
      if (scope != null && entry.scope != scope) continue;
      final amount = BigInt.from(entry.amountCents);
      if (entry.isWithdrawal) {
        if (entry.type == EntryType.income) {
          _receivedCents += amount;
        } else {
          _sentCents += amount;
        }
      } else if (entry.type == EntryType.income) {
        _incomeCents += amount;
      } else {
        _expenseCents += amount;
      }
    }
    balanceCents =
        incomeCents -
        expenseCents +
        (scope == null ? BigInt.zero : receivedCents - sentCents);
  }
  BigInt _incomeCents = BigInt.zero;
  BigInt _expenseCents = BigInt.zero;
  BigInt _receivedCents = BigInt.zero;
  BigInt _sentCents = BigInt.zero;
  BigInt get incomeCents => _incomeCents;
  BigInt get expenseCents => _expenseCents;
  BigInt get receivedCents => _receivedCents;
  BigInt get sentCents => _sentCents;
  late final BigInt balanceCents;

  MonthSummary checkedSummary() {
    final max = BigInt.from(maxMoneyCents);
    for (final amount in [
      incomeCents,
      expenseCents,
      receivedCents,
      sentCents,
      balanceCents.abs(),
    ]) {
      if (amount > max) throw RangeError('Totais fora do intervalo suportado');
    }
    return MonthSummary(
      incomeCents: incomeCents.toInt(),
      expenseCents: expenseCents.toInt(),
      receivedCents: receivedCents.toInt(),
      sentCents: sentCents.toInt(),
      balanceOverrideCents: balanceCents.toInt(),
    );
  }
}
