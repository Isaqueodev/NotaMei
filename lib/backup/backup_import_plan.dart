import '../annual/annual_summary.dart';
import '../data/entry_totals.dart';
import '../data/entry_record.dart';
import 'financial_backup.dart';

enum BackupImportFailure { conflict, stale, invalid, storage }

final class BackupImportException implements Exception {
  const BackupImportException(this.reason);
  final BackupImportFailure reason;
  @override
  String toString() => switch (reason) {
    BackupImportFailure.conflict =>
      'Existem conflitos. Nenhum registro foi importado.',
    BackupImportFailure.stale =>
      'O histórico mudou. Selecione o backup novamente para conferir a prévia.',
    BackupImportFailure.invalid =>
      'Os dados são inválidos ou ultrapassam os limites suportados.',
    BackupImportFailure.storage =>
      'Não foi possível concluir a importação. Tente novamente.',
  };
}

bool sameBackupRecord(EntryRecord a, EntryRecord b) =>
    a.id == b.id &&
    a.type == b.type &&
    a.scope == b.scope &&
    a.amountCents == b.amountCents &&
    a.category == b.category &&
    a.date.toIso8601String() == b.date.toIso8601String() &&
    a.note == b.note &&
    a.withdrawalId == b.withdrawalId;

class BackupImportPlan {
  BackupImportPlan._(
    this.before,
    this.backup,
    this.additions,
    this.identicalCount,
    this.conflictCount,
  );
  factory BackupImportPlan.prepare(
    List<EntryRecord> current,
    FinancialBackup backup,
  ) {
    final local = {for (final entry in current) entry.id: entry};
    final additions = <EntryRecord>[];
    var identical = 0;
    var conflicts = 0;
    for (final entry in backup.entries) {
      final existing = local[entry.id];
      if (existing == null) {
        additions.add(entry);
      } else if (sameBackupRecord(existing, entry)) {
        identical++;
      } else {
        conflicts++;
      }
    }
    if (conflicts == 0) {
      try {
        // Validate both existing and merged histories, including complete pairs.
        FinancialBackupCodec.encode(current, createdAt: backup.createdAt);
        final merged = [...current, ...additions];
        FinancialBackupCodec.encode(merged, createdAt: backup.createdAt);
        final months = <(int, int), List<EntryRecord>>{};
        final years = <int, List<EntryRecord>>{};
        for (final entry in merged) {
          (months[(entry.date.year, entry.date.month)] ??= []).add(entry);
          (years[entry.date.year] ??= []).add(entry);
        }
        for (final entries in months.values) {
          for (final scope in <EntryScope?>[null, ...EntryScope.values]) {
            EntryTotals.calculate(entries, scope: scope).checkedSummary();
          }
        }
        for (final year in years.entries) {
          recordedAnnualIncome(year.value, year.key);
        }
      } catch (_) {
        throw const BackupImportException(BackupImportFailure.invalid);
      }
    }
    return BackupImportPlan._(
      List.unmodifiable(current),
      backup,
      List.unmodifiable(additions),
      identical,
      conflicts,
    );
  }
  final List<EntryRecord> before;
  final FinancialBackup backup;
  final List<EntryRecord> additions;
  final int identicalCount;
  final int conflictCount;
  int get addedCount => additions.length;
}
