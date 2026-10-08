import 'dart:io';

void main() {
  final colors = ['backgroundPrimary', 'backgroundSecondary', 'backgroundTertiary', 'primaryGreen', 'primaryGreenHover', 'militaryOlive', 'successGreen', 'warningAmber', 'criticalRed', 'infoBlue', 'borderSubtle', 'borderStrong', 'textPrimary', 'textSecondary', 'textMuted'];
  final dir = Directory('c:/Users/yagel/Downloads/HOPEL/lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var lines = content.split('\n');
      var changed = false;
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line.contains('const ') && colors.any((c) => line.contains('AppTheme.' + c))) {
          lines[i] = line.replaceAll(RegExp(r'\bconst\s+'), '');
          changed = true;
        }
      }
      if (changed) {
        entity.writeAsStringSync(lines.join('\n'));
      }
    }
  }
  print('Done');
}
