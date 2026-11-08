import 'package:file_picker/file_picker.dart';
import 'picked_spreadsheet_file.dart';

Future<PickedSpreadsheetFile?> pickSpreadsheetImpl({bool allowAnyFile = false}) async {
  final files = await FilePicker.pickFiles(
    type: allowAnyFile ? FileType.any : FileType.custom,
    allowedExtensions: allowAnyFile ? null : ['xlsx', 'xls', 'csv', 'tsv'],
  );
  final file = files.firstOrNull;
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return PickedSpreadsheetFile(name: file.name, bytes: bytes);
}
