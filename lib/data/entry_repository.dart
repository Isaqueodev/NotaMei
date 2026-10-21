import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

import '../annual/annual_summary.dart';
import 'entry_record.dart';
import 'entry_totals.dart';

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
        version: 2,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE entries ADD COLUMN withdrawal_id TEXT',
            );
          }
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE entries (
              id TEXT PRIMARY KEY NOT NULL CHECK(length(trim(id)) > 0),
              type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
              scope TEXT NOT NULL CHECK(scope IN ('business', 'personal')),
              amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
              category TEXT NOT NULL CHECK(length(trim(category)) > 0),
              date TEXT NOT NULL,
              note TEXT,
              withdrawal_id TEXT
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
    _entries = await _read(db);
  }

  Future<List<EntryRecord>> _read(DatabaseExecutor db) async {
    final rows = await db.query('entries', orderBy: 'date DESC, id ASC');
    return List.unmodifiable(
      rows.map(
        (row) => EntryRecord(
          id: row['id'] as String,
          type: EntryType.values.byName(row['type'] as String),
          scope: EntryScope.values.byName(row['scope'] as String),
          amountCents: row['amount_cents'] as int,
          category: row['category'] as String,
          date: DateTime.parse(row['date'] as String),
          note: row['note'] as String?,
          withdrawalId: row['withdrawal_id'] as String?,
        ),
      ),
    );
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<void> saveWithdrawal({
    required String operationId,
    required int amountCents,
    required DateTime date,
    String? note,
  }) => _enqueue(() async {
    await initialize();
    if (operationId.trim().isEmpty || amountCents <= 0) {
      throw ArgumentError('Retirada inválida');
    }
    final snapshot = await _database!.transaction((txn) async {
      for (final scope in EntryScope.values) {
        final id = 'withdrawal:$operationId:${scope.name}';
        final values = <String, Object?>{
          'id': id,
          'withdrawal_id': operationId,
          'type': scope == EntryScope.business ? 'expense' : 'income',
          'scope': scope.name,
          'amount_cents': amountCents,
          'category': 'Retirada do titular',
          'date': date.toIso8601String(),
          'note': note,
        };
        final previous = await txn.query(
          'entries',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (previous.isEmpty) {
          await txn.insert('entries', values);
        } else {
          if (previous.single['withdrawal_id'] != operationId) {
            throw StateError('Colisão de identificador');
          }
          await txn.update('entries', values, where: 'id = ?', whereArgs: [id]);
        }
      }
      final snapshot = await _read(txn);
      _validateFor(snapshot, date);
      return snapshot;
    });
    _entries = snapshot;
    notifyListeners();
  });

  void _validateFor(
    List<EntryRecord> entries,
    DateTime date, {
    bool allScopes = true,
  }) {
    final month = entries.where(
      (e) => e.date.year == date.year && e.date.month == date.month,
    );
    for (final scope
        in allScopes
            ? <EntryScope?>[null, ...EntryScope.values]
            : <EntryScope?>[EntryScope.business]) {
      EntryTotals.calculate(month, scope: scope).checkedSummary();
    }
    recordedAnnualIncome(entries, date.year);
  }

  Future<void> upsert(EntryRecord entry) => _enqueue(() async {
    await initialize();
    if (entry.isWithdrawal) throw StateError('Use o formulário de retirada');
    final snapshot = await _database!.transaction((txn) async {
      final previous = await txn.query(
        'entries',
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      if (previous.isNotEmpty && previous.single['withdrawal_id'] != null) {
        throw StateError(
          'Use o formulário de retirada para alterar as duas pontas',
        );
      }
      final values = <String, Object?>{
        'id': entry.id,
        'type': entry.type.name,
        'scope': entry.scope.name,
        'amount_cents': entry.amountCents,
        'category': entry.category,
        'date': entry.date.toIso8601String(),
        'note': entry.note,
      };
      if (previous.isEmpty) {
        await txn.insert('entries', values);
      } else {
        await txn.update(
          'entries',
          values,
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      }
      final snapshot = await _read(txn);
      if (entry.scope == EntryScope.business) {
        _validateFor(snapshot, entry.date, allScopes: false);
      }
      return snapshot;
    });
    _entries = snapshot;
    notifyListeners();
  });

  Future<void> remove(String id) => _enqueue(() async {
    await initialize();
    final snapshot = await _database!.transaction((txn) async {
      final rows = await txn.query('entries', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return null;
      final operation = rows.single['withdrawal_id'];
      await txn.delete(
        'entries',
        where: operation == null ? 'id = ?' : 'withdrawal_id = ?',
        whereArgs: [operation ?? id],
      );
      return _read(txn);
    });
    if (snapshot != null) {
      _entries = snapshot;
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

  MonthSummary summaryFor(DateTime month) => EntryTotals.calculate(
    forMonth(month),
    scope: EntryScope.business,
  ).checkedSummary();

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
