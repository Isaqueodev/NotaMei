import '../data/entry_repository.dart';
import '../export/export_document.dart';
import '../export/export_gateway.dart';
import 'financial_backup.dart';

enum BackupCreationFailure { busy, preparation, save }

/// Safe messages only; deliberately does not retain an exception with file data.
class BackupCreationException implements Exception {
  const BackupCreationException(this.reason);
  final BackupCreationFailure reason;

  @override
  String toString() => switch (reason) {
    BackupCreationFailure.busy => 'Já existe um backup sendo salvo.',
    BackupCreationFailure.preparation =>
      'Não foi possível preparar o backup financeiro.',
    BackupCreationFailure.save =>
      'Não foi possível confirmar o salvamento do backup.',
  };
}

/// Creates a whole-history document. Does not restore or modify financial data.
class BackupCreationService {
  BackupCreationService({
    required EntryRepository repository,
    DateTime Function()? now,
  }) : // Keep the public named argument without exposing a private parameter.
       // ignore: prefer_initializing_formals
       _repository = repository,
       _now = now ?? DateTime.now;

  final EntryRepository _repository;
  final DateTime Function() _now;

  bool _saving = false;

  Future<ExportOutcome> save() async {
    if (_saving) {
      throw const BackupCreationException(BackupCreationFailure.busy);
    }
    _saving = true;
    try {
      final document = await prepare();
      try {
        return await ExportGateway().saveDocument(document);
      } catch (_) {
        throw const BackupCreationException(BackupCreationFailure.save);
      }
    } finally {
      _saving = false;
    }
  }

  Future<ExportDocument> prepare() async {
    try {
      final snapshot = await _repository.snapshotForBackup();
      final createdAt = _now().toUtc();
      return ExportDocument(
        bytes: FinancialBackupCodec.encode(snapshot, createdAt: createdAt),
        filename: 'NotaMei_backup_${createdAt.microsecondsSinceEpoch}.json',
        mimeType: 'application/json',
      );
    } catch (_) {
      throw const BackupCreationException(BackupCreationFailure.preparation);
    }
  }
}
