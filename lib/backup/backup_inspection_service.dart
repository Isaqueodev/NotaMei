import 'dart:io';
import 'dart:typed_data';

import '../data/entry_record.dart';
import 'financial_backup.dart';

enum BackupInspectionFailure { tooLarge, invalid, read }

/// Deliberately retains neither the source exception nor file contents/paths.
final class BackupInspectionException implements Exception {
  const BackupInspectionException(this.reason);
  final BackupInspectionFailure reason;

  @override
  String toString() => switch (reason) {
    BackupInspectionFailure.tooLarge => 'O backup excede o tamanho permitido.',
    BackupInspectionFailure.invalid =>
      'Backup financeiro inválido ou incompatível.',
    BackupInspectionFailure.read => 'Não foi possível ler o arquivo de backup.',
  };
}

/// Read-only decoded content; not authorization to restore a database.
class BackupInspection {
  const BackupInspection._(this.backup, this.byteCount);
  final FinancialBackup backup;
  final int byteCount;
  int get recordCount => backup.entries.length;
  int get businessCount =>
      backup.entries.where((e) => e.scope == EntryScope.business).length;
  int get personalCount => recordCount - businessCount;
  int get regularRecordCount =>
      backup.entries.where((e) => !e.isWithdrawal).length;
  int get withdrawalOperations => backup.entries
      .where((e) => e.isWithdrawal && e.scope == EntryScope.business)
      .length;

  /// Original representation, selected by year/month/day only (not UTC instant).
  DateTime? get earliestDate => _dateBound(earliest: true);
  DateTime? get latestDate => _dateBound(earliest: false);

  DateTime? _dateBound({required bool earliest}) {
    DateTime? bound;
    for (final entry in backup.entries) {
      if (bound == null ||
          (earliest
              ? _compareCivil(entry.date, bound) < 0
              : _compareCivil(entry.date, bound) > 0)) {
        bound = entry.date;
      }
    }
    return bound;
  }

  static int _compareCivil(DateTime left, DateTime right) {
    final year = left.year.compareTo(right.year);
    if (year != 0) return year;
    final month = left.month.compareTo(right.month);
    return month != 0 ? month : left.day.compareTo(right.day);
  }
}

class BackupInspectionService {
  const BackupInspectionService();

  Future<BackupInspection> inspectFile(File file) async {
    try {
      return await inspectStream(file.openRead());
    } on BackupInspectionException {
      rethrow;
    } catch (_) {
      throw const BackupInspectionException(BackupInspectionFailure.read);
    }
  }

  Future<BackupInspection> inspectStream(Stream<List<int>> source) async {
    final builder = BytesBuilder();
    try {
      await for (final chunk in source) {
        if (chunk.length > maxFinancialBackupBytes - builder.length) {
          throw const BackupInspectionException(
            BackupInspectionFailure.tooLarge,
          );
        }
        if (chunk.any((byte) => byte < 0 || byte > 255)) {
          throw const BackupInspectionException(
            BackupInspectionFailure.invalid,
          );
        }
        builder.add(chunk);
      }
    } on BackupInspectionException {
      rethrow;
    } catch (_) {
      throw const BackupInspectionException(BackupInspectionFailure.read);
    }
    try {
      final bytes = builder.takeBytes();
      return BackupInspection._(
        FinancialBackupCodec.decode(bytes),
        bytes.length,
      );
    } catch (_) {
      throw const BackupInspectionException(BackupInspectionFailure.invalid);
    }
  }
}
