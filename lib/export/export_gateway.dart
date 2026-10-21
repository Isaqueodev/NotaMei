import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_export.dart';

enum ExportOutcome { saved, shared, cancelled, unconfirmed }

typedef ExportAction = Future<ExportOutcome> Function(CsvReport report);

/// Only exports the immutable report. Never writes to the financial repository.
class ExportGateway {
  ExportGateway({Future<ShareResult> Function(ShareParams)? shareFile})
    : _shareFile = shareFile ?? SharePlus.instance.share;

  final Future<ShareResult> Function(ShareParams) _shareFile;

  Future<ExportOutcome> save(CsvReport report) async {
    final destination = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: report.bytes,
        fileName: report.filename,
        mimeTypesFilter: const ['text/csv'],
        localOnly: true,
      ),
    );
    return destination == null ? ExportOutcome.cancelled : ExportOutcome.saved;
  }

  Future<ExportOutcome> share(CsvReport report) async {
    final result = await _shareFile(
      ShareParams(
        files: [XFile.fromData(report.bytes, mimeType: 'text/csv')],
        fileNameOverrides: [report.filename],
        title: 'Exportação NotaMei',
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => ExportOutcome.shared,
      ShareResultStatus.dismissed => ExportOutcome.cancelled,
      ShareResultStatus.unavailable => ExportOutcome.unconfirmed,
    };
  }
}
