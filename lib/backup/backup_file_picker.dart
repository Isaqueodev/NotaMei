import 'package:flutter/services.dart';

import 'backup_inspection_service.dart';

/// Android SAF returns bounded bytes, never an assumed path for content:// URIs.
class BackupFilePicker {
  const BackupFilePicker();
  static const _channel = MethodChannel('br.edu.notamei/backup');
  Future<BackupInspection?> pick() async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('pickBackup');
      if (bytes == null) return null;
      return await const BackupInspectionService().inspectStream(
        Stream.value(bytes),
      );
    } on BackupInspectionException {
      rethrow;
    } on PlatformException catch (e) {
      throw BackupInspectionException(
        e.code == 'too_large'
            ? BackupInspectionFailure.tooLarge
            : BackupInspectionFailure.read,
      );
    } catch (_) {
      throw const BackupInspectionException(BackupInspectionFailure.read);
    }
  }
}
