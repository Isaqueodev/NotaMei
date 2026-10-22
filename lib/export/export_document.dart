import 'dart:typed_data';

/// Bytes and metadata ready for a native save/share action, not a database backup.
class ExportDocument {
  ExportDocument({
    required Uint8List bytes,
    required this.filename,
    required this.mimeType,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}
