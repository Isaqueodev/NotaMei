enum EntryType { income, expense }

enum EntryScope { business, personal }

/// A manually recorded amount. Values are always positive integer cents.
class EntryRecord {
  EntryRecord({
    required this.id,
    required this.type,
    required this.scope,
    required this.amountCents,
    required this.category,
    required this.date,
    this.note,
    this.withdrawalId,
  }) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id');
    if (amountCents <= 0) {
      throw ArgumentError.value(amountCents, 'amountCents');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError.value(category, 'category');
    }
  }

  final String id;
  final EntryType type;
  final EntryScope scope;
  final int amountCents;
  final String category;
  final DateTime date;
  final String? note;
  final String? withdrawalId;
  bool get isWithdrawal => withdrawalId != null;
}

class MonthSummary {
  const MonthSummary({
    required this.incomeCents,
    required this.expenseCents,
    this.receivedCents = 0,
    this.sentCents = 0,
    this.balanceOverrideCents,
  });

  final int incomeCents;
  final int expenseCents;
  final int receivedCents;
  final int sentCents;
  final int? balanceOverrideCents;
  int get balanceCents => balanceOverrideCents ?? incomeCents - expenseCents;
}
