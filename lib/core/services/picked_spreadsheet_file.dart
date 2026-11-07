import 'dart:typed_data';

class PickedSpreadsheetFile {
  final String name;
  final Uint8List bytes;

  const PickedSpreadsheetFile({
    required this.name,
    required this.bytes,
  });
}

