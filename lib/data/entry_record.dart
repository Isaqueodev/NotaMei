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
}

class MonthSummary {
  const MonthSummary({required this.incomeCents, required this.expenseCents});

  final int incomeCents;
  final int expenseCents;
  int get balanceCents => incomeCents - expenseCents;
}
