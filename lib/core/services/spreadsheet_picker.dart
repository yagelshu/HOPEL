import 'picked_spreadsheet_file.dart';
import 'spreadsheet_picker_stub.dart'
    if (dart.library.js_interop) 'spreadsheet_picker_web.dart';

export 'picked_spreadsheet_file.dart';

class SpreadsheetPicker {
  /// Opens a mobile-PWA-friendly file picker with full Excel/CSV MIME types.
  /// Set [allowAnyFile] to `true` to bypass OS MIME filtering completely (`*/*`).
  static Future<PickedSpreadsheetFile?> pick({bool allowAnyFile = false}) =>
      pickSpreadsheetImpl(allowAnyFile: allowAnyFile);
}

