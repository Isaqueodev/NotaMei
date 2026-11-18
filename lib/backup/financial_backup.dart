import 'dart:convert';
import 'dart:typed_data';

import '../core/money.dart';
import '../data/entry_record.dart';

const maxFinancialBackupBytes = 10 * 1024 * 1024;
const maxFinancialBackupEntries = 10000;

/// Validated financial records only. This snapshot does not restore a database.
class FinancialBackup {
  FinancialBackup._(this.createdAt, List<EntryRecord> entries)
    : entries = List.unmodifiable(entries);

  final DateTime createdAt;
  final List<EntryRecord> entries;
}

/// Version 1 UTF-8 JSON, without I/O, preferences, encryption or authentication.
/// Validation failures never include the supplied financial content as source.
abstract final class FinancialBackupCodec {
  /// The caller must supply the complete history, not the current screen filter.
  static Uint8List encode(
    List<EntryRecord> entries, {
    required DateTime createdAt,
  }) {
    if (entries.length > maxFinancialBackupEntries) _invalid();
    final rows = entries.map(_row).toList();
    _entries(rows);
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'notamei-financial-backup',
          'version': 1,
          'createdAt': createdAt.toUtc().toIso8601String(),
          'entries': rows,
        }),
      ),
    );
    if (bytes.length > maxFinancialBackupBytes) _invalid();
    return bytes;
  }

  static FinancialBackup decode(Uint8List bytes) {
    if (bytes.length > maxFinancialBackupBytes) _invalid();
    try {
      final data = _object(jsonDecode(utf8.decode(bytes)), {
        'format',
        'version',
        'createdAt',
        'entries',
      });
      if (data['format'] != 'notamei-financial-backup' ||
          data['version'] is! int ||
          data['version'] != 1 ||
          data['entries'] is! List) {
        _invalid();
      }
      final createdAt = _date(data['createdAt'], utc: true);
      final entries = _entries(data['entries'] as List);
      return FinancialBackup._(createdAt, entries);
    } on FormatException {
      _invalid();
    }
  }

  static Map<String, Object?> _row(EntryRecord entry) => {
    'id': entry.id,
    'type': entry.type.name,
    'scope': entry.scope.name,
    'amountCents': entry.amountCents.toString(),
    'category': entry.category,
    'date': entry.date.toIso8601String(),
    'note': entry.note,
    'withdrawalId': entry.withdrawalId,
  };

  static List<EntryRecord> _entries(List<dynamic> rows) {
    if (rows.length > maxFinancialBackupEntries) _invalid();
    final ids = <String>{};
    var textUnits = 0;
    final entries = rows.map((value) {
      final row = _object(value, {
        'id',
        'type',
        'scope',
        'amountCents',
        'category',
        'date',
        'note',
        'withdrawalId',
      });
      // Bound serialization work before creating escaped JSON/UTF-8 buffers.
      for (final field in row.values.whereType<String>()) {
        textUnits += field.length;
        if (textUnits > maxFinancialBackupBytes) _invalid();
      }
      final id = _text(row['id']);
      if (!ids.add(id) ||
          !EntryType.values.any((v) => v.name == row['type']) ||
          !EntryScope.values.any((v) => v.name == row['scope'])) {
        _invalid();
      }
      final cents = row['amountCents'];
      if (cents is! String || !RegExp(r'^[1-9][0-9]{0,18}$').hasMatch(cents)) {
        _invalid();
      }
      final amount = BigInt.parse(cents);
      if (amount > BigInt.from(maxMoneyCents)) _invalid();
      final note = row['note'];
      final operation = row['withdrawalId'];
      if (note != null && note is! String) _invalid();
      if (operation != null) _text(operation);
      return EntryRecord(
        id: id,
        type: EntryType.values.byName(row['type'] as String),
        scope: EntryScope.values.byName(row['scope'] as String),
        amountCents: amount.toInt(),
        category: _text(row['category']),
        date: _date(row['date']),
        note: note as String?,
        withdrawalId: operation as String?,
      );
    }).toList();
    _validateWithdrawals(entries);
    return entries;
  }

  static void _validateWithdrawals(List<EntryRecord> entries) {
    final groups = <String, List<EntryRecord>>{};
    for (final entry in entries.where((entry) => entry.isWithdrawal)) {
      final operation = entry.withdrawalId!;
      if (entry.id != 'withdrawal:$operation:${entry.scope.name}' ||
          entry.category != 'Retirada do titular') {
        _invalid();
      }
      (groups[operation] ??= []).add(entry);
    }
    for (final pair in groups.values) {
      final sent = pair
          .where((entry) => entry.scope == EntryScope.business)
          .toList();
      final received = pair
          .where((entry) => entry.scope == EntryScope.personal)
          .toList();
      if (pair.length != 2 || sent.length != 1 || received.length != 1) {
        _invalid();
      }
      final business = sent.single;
      final personal = received.single;
      if (business.type != EntryType.expense ||
          personal.type != EntryType.income ||
          business.amountCents != personal.amountCents ||
          business.date.toIso8601String() != personal.date.toIso8601String() ||
          business.note != personal.note) {
        _invalid();
      }
    }
  }

  static String _text(Object? value) {
    if (value is! String || value.trim().isEmpty) _invalid();
    return value;
  }

  static Map<String, dynamic> _object(Object? value, Set<String> keys) {
    if (value is! Map<String, dynamic> ||
        value.length != keys.length ||
        !value.keys.every(keys.contains)) {
      _invalid();
    }
    return value;
  }

  static DateTime _date(Object? value, {bool utc = false}) {
    if (value is! String) _invalid();
    final date = DateTime.tryParse(value);
    if (date == null ||
        date.toIso8601String() != value ||
        (utc && !date.isUtc)) {
      _invalid();
    }
    return date;
  }

  static Never _invalid() => throw const FormatException(
    'Backup financeiro inválido ou incompatível.',
  );
}
