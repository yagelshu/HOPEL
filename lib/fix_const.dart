import 'dart:io';

void main() async {
  print('Running flutter analyze...');
  final result = await Process.run('flutter.bat', ['analyze', '--no-fatal-infos', '--no-fatal-warnings']);
  final lines = result.stdout.toString().split('\n').followedBy(result.stderr.toString().split('\n'));
  
  final regex = RegExp(r'invalid_constant.*? - (.*?):(\d+):(\d+)');
  Map<String, List<int>> fileToLines = {};
  
  for (final line in lines) {
    if (line.contains('invalid_constant') || line.contains('non_constant_default_value')) {
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final pathLineCol = parts[2].trim().split(':');
        if (pathLineCol.length >= 2) {
          final path = pathLineCol[0].trim();
          final lineNum = int.tryParse(pathLineCol[1].trim());
          if (path.isNotEmpty && lineNum != null) {
            fileToLines.putIfAbsent(path, () => []).add(lineNum);
          }
        }
      }
    }
  }

  print('Found ${fileToLines.length} files with invalid constants.');
  
  for (final entry in fileToLines.entries) {
    final path = entry.key;
    final lineNums = entry.value;
    final file = File(path);
    if (!file.existsSync()) continue;
    
    final fileLines = file.readAsStringSync().split('\n');
    bool changed = false;
    
    for (final lineNum in lineNums) {
      if (lineNum > 0 && lineNum <= fileLines.length) {
        int targetIdx = lineNum - 1;
        bool found = false;
        
        // Search backwards up to 20 lines for a 'const ' keyword
        for (int i = targetIdx; i >= 0 && i >= targetIdx - 20; i--) {
          if (fileLines[i].contains('const ')) {
            // Check if it's not a const variable declaration like 'const String x ='
            if (!fileLines[i].contains('const String') && !fileLines[i].contains('const int') && !fileLines[i].contains('const double')) {
              fileLines[i] = fileLines[i].replaceFirst('const ', '');
              changed = true;
              found = true;
              break;
            }
          }
        }
      }
    }
    
    if (changed) {
      file.writeAsStringSync(fileLines.join('\n'));
      print('Fixed $path');
    }
  }
}
