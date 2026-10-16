import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

import '../core/money.dart';
import 'entry_record.dart';

/// Local SQLite storage. Await initialize before reading the initial snapshot.
/// Mutations are serialized and listeners see only successfully persisted data.
class EntryRepository extends ChangeNotifier {
  EntryRepository({DatabaseFactory? databaseFactory, String? path})
    : _factory = databaseFactory ?? sqlite.databaseFactory,
      // Public constructor uses `path` rather than exposing a private parameter.
      // ignore: prefer_initializing_formals
      _path = path;

  final DatabaseFactory _factory;
  final String? _path;
  Database? _database;
  Future<void>? _initializing;
  Future<void> _tail = Future<void>.value();
  List<EntryRecord> _entries = const [];

  List<EntryRecord> get entries => _entries;

  Future<void> initialize() =>
      _initializing ??= _open().onError((Object error, StackTrace stack) {
        _initializing = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _open() async {
    final path = _path ?? '${await _factory.getDatabasesPath()}/notamei.db';
    final db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE entries (
              id TEXT PRIMARY KEY NOT NULL CHECK(length(trim(id)) > 0),
              type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
              scope TEXT NOT NULL CHECK(scope IN ('business', 'personal')),
              amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
              category TEXT NOT NULL CHECK(length(trim(category)) > 0),
              date TEXT NOT NULL,
              note TEXT
            )
          ''');
        },
      ),
    );
    try {
      await _refresh(db);
      _database = db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<void> _refresh(Database db) async {
    final rows = await db.query('entries', orderBy: 'date DESC, id ASC');
    _entries = List.unmodifiable(
      rows.map(
        (row) => EntryRecord(
          id: row['id'] as String,
          type: EntryType.values.byName(row['type'] as String),
          scope: EntryScope.values.byName(row['scope'] as String),
          amountCents: row['amount_cents'] as int,
          category: row['category'] as String,
          date: DateTime.parse(row['date'] as String),
          note: row['note'] as String?,
        ),
      ),
    );
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<void> upsert(EntryRecord entry) => _enqueue(() async {
    await initialize();
    if (entry.scope == EntryScope.business) {
      var monthCents = entry.amountCents;
      var yearIncomeCents = entry.amountCents;
      for (final current in _entries) {
        if (current.id == entry.id ||
            current.scope != EntryScope.business ||
            current.type != entry.type ||
            current.date.year != entry.date.year) {
          continue;
        }
        if (current.date.month == entry.date.month) {
          monthCents = checkedAddCents(monthCents, current.amountCents);
        }
        if (entry.type == EntryType.income) {
          yearIncomeCents = checkedAddCents(
            yearIncomeCents,
            current.amountCents,
          );
        }
      }
    }
    await _database!.insert('entries', {
      'id': entry.id,
      'type': entry.type.name,
      'scope': entry.scope.name,
      'amount_cents': entry.amountCents,
      'category': entry.category,
      'date': entry.date.toIso8601String(),
      'note': entry.note,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _refresh(_database!);
    notifyListeners();
  });

  Future<void> remove(String id) => _enqueue(() async {
    await initialize();
    final count = await _database!.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count > 0) {
      await _refresh(_database!);
      notifyListeners();
    }
  });

  /// Uses the recorded calendar year/month, without timezone conversion.
  List<EntryRecord> forMonth(DateTime month) => List.unmodifiable(
    _entries.where(
      (entry) =>
          entry.date.year == month.year && entry.date.month == month.month,
    ),
  );

  MonthSummary summaryFor(DateTime month) {
    var income = 0;
    var expense = 0;
    for (final entry in forMonth(month)) {
      if (entry.scope != EntryScope.business) continue;
      switch (entry.type) {
        case EntryType.income:
          income = checkedAddCents(income, entry.amountCents);
        case EntryType.expense:
          expense = checkedAddCents(expense, entry.amountCents);
      }
    }
    return MonthSummary(incomeCents: income, expenseCents: expense);
  }

  /// Await before disposing or deleting a database file.
  Future<void> close() => _enqueue(() async {
    final opening = _initializing;
    if (opening != null) await opening;
    await _database?.close();
    _database = null;
    _initializing = null;
    _entries = const [];
  });
}
