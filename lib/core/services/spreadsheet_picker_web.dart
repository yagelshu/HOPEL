import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'picked_spreadsheet_file.dart';

@JS('eval')
external JSAny? _jsEval(JSString code);

@JS('__hopalPickSpreadsheet')
external JSPromise<JSString?> _jsPickSpreadsheet(JSBoolean allowAny);

bool _pickerBridgeInstalled = false;

void _ensurePickerBridge() {
  if (_pickerBridgeInstalled) return;
  _jsEval('''
    window.__hopalPickSpreadsheet = function(allowAny) {
      return new Promise(function(resolve) {
        var input = document.createElement('input');
        input.type = 'file';
        input.style.position = 'fixed';
        input.style.top = '-9999px';
        input.style.opacity = '0';
        if (!allowAny) {
          input.setAttribute(
            'accept',
            '.xlsx,.xls,.csv,.tsv,' +
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,' +
            'application/vnd.ms-excel,' +
            'text/csv,text/comma-separated-values,text/tab-separated-values,text/plain'
          );
        }
        var settled = false;
        function finish(val) {
          if (settled) return;
          settled = true;
          try { document.body.removeChild(input); } catch (_) {}
          resolve(val);
        }
        input.addEventListener('change', function() {
          var file = input.files && input.files[0];
          if (!file) { finish(null); return; }
          var reader = new FileReader();
          reader.onload = function() {
            var dataUrl = reader.result || '';
            var commaIdx = dataUrl.indexOf(',');
            var b64 = commaIdx >= 0 ? dataUrl.substring(commaIdx + 1) : '';
            finish(JSON.stringify({ name: file.name || 'roster.xlsx', base64: b64 }));
          };
          reader.onerror = function() { finish(null); };
          reader.readAsDataURL(file);
        });
        input.addEventListener('cancel', function() { finish(null); });
        document.body.appendChild(input);
        input.click();
      });
    };
  '''
      .toJS);
  _pickerBridgeInstalled = true;
}

Future<PickedSpreadsheetFile?> pickSpreadsheetImpl({bool allowAnyFile = false}) async {
  _ensurePickerBridge();
  final rawJs = await _jsPickSpreadsheet(allowAnyFile.toJS).toDart;
  if (rawJs == null) return null;
  final raw = rawJs.toDart;
  if (raw.isEmpty) return null;
  final map = jsonDecode(raw) as Map<String, dynamic>;
  final name = (map['name'] as String?) ?? 'roster.xlsx';
  final b64 = (map['base64'] as String?) ?? '';
  if (b64.isEmpty) return null;
  return PickedSpreadsheetFile(
    name: name,
    bytes: base64Decode(b64),
  );
}
