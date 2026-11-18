import 'dart:typed_data';

/// Bytes and metadata for native save/share. The producer defines the format;
/// this transport container neither creates nor restores database records.
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
