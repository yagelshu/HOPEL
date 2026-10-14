import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/soldier_import_service.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';

/// 3 steps: pick file -> map columns -> preview & save.
class SoldiersImportScreen extends ConsumerStatefulWidget {
  const SoldiersImportScreen({super.key});

  @override
  ConsumerState<SoldiersImportScreen> createState() => _SoldiersImportScreenState();
}

class _SoldiersImportScreenState extends ConsumerState<SoldiersImportScreen> {
  ImportTable? _table;
  String? _fileName;
  List<SoldierField> _mapping = [];
  bool _saving = false;

  List<ImportedSoldier> get _preview =>
      _table == null ? [] : SoldierImportService.apply(_table!, _mapping);

  bool get _hasName =>
      _mapping.contains(SoldierField.fullName) ||
      _mapping.contains(SoldierField.firstName) ||
      _mapping.contains(SoldierField.lastName);

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    final file = files.firstOrNull;
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final table = SoldierImportService.parse(bytes, file.name);
      setState(() {
        _table = table;
        _fileName = file.name;
        _mapping = SoldierImportService.guessMapping(table.headers);
      });
    } on FormatException catch (e) {
      if (mounted) HopalFeedback.showError(context, e.message);
    } catch (e) {
      if (mounted) HopalFeedback.showError(context, 'לא ניתן לקרוא את הקובץ: $e');
    }
  }

  Future<void> _save() async {
    final unitId = AuthService().currentUser?.unitId;
    if (unitId == null) {
      HopalFeedback.showError(context, 'לא נמצאה פלוגה למשתמש');
      return;
    }
    final soldiers = _preview;
    if (soldiers.isEmpty) return;
    setState(() => _saving = true);
    try {
      await SoldierImportService.save(soldiers, unitId);
      ref.invalidate(soldiersProvider);
      if (!mounted) return;
      HopalFeedback.showSuccess(context, '${soldiers.length} חיילים נשמרו בהצלחה');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) HopalFeedback.showError(context, 'שגיאה בשמירה: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text('ייבוא רשימת פלוגה',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _table == null ? _buildPickStep() : _buildMapStep(),
    );
  }

  Widget _buildPickStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileSpreadsheet, size: 72, color: AppTheme.primaryGreen),
            const SizedBox(height: AppTheme.spacing16),
            Text('העלה קובץ אקסל של הפלוגה',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'קובץ ‎.xlsx או ‎.csv. השורה הראשונה צריכה להיות כותרות.\nבשלב הבא תבחר איזו עמודה היא מה.\nחייל שכבר קיים (לפי מספר אישי) יתעדכן ולא ישוכפל.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppTheme.spacing24),
            HopalButton(
              key: const Key('import_pick_file'),
              label: 'בחר קובץ',
              icon: LucideIcons.upload,
              onPressed: _pickFile,
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStep() {
    final table = _table!;
    final preview = _preview;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            children: [
              Row(
                children: [
                  Icon(LucideIcons.fileCheck, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$_fileName • ${table.rows.length} שורות',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  TextButton(onPressed: _pickFile, child: const Text('קובץ אחר')),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text('התאמת עמודות',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppTheme.spacing8),
              for (var i = 0; i < table.headers.length; i++) _buildMappingRow(i),
              const SizedBox(height: AppTheme.spacing24),
              Text('תצוגה מקדימה (${preview.length} חיילים)',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppTheme.spacing8),
              if (!_hasName)
                Text('יש לסמן לפחות עמודת שם אחת',
                    style: TextStyle(color: AppTheme.criticalRed)),
              ...preview.take(8).map((s) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(LucideIcons.user, color: AppTheme.primaryGreen, size: 18),
                    title: Text(s.name, style: TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(
                      [
                        if (s.personalNumber != null) 'מ.א ${s.personalNumber}',
                        if (s.phone != null) s.phone!,
                        if (s.platoon != null) 'מחלקה ${s.platoon}',
                      ].join(' • '),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  )),
              if (preview.length > 8)
                Text('ועוד ${preview.length - 8}...', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: HopalButton(
              key: const Key('import_save'),
              label: 'ייבא ${preview.length} חיילים',
              icon: LucideIcons.check,
              isLoading: _saving,
              isExpanded: true,
              onPressed: (_hasName && preview.isNotEmpty && !_saving) ? _save : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingRow(int i) {
    final table = _table!;
    final sample = table.rows.map((r) => r[i]).firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(
            color: _mapping[i] == SoldierField.ignore ? AppTheme.borderSubtle : AppTheme.primaryGreen,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(table.headers[i].isEmpty ? 'עמודה ${i + 1}' : table.headers[i],
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  if (sample.isNotEmpty)
                    Text('לדוגמה: $sample',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            DropdownButton<SoldierField>(
              value: _mapping[i],
              underline: const SizedBox.shrink(),
              dropdownColor: AppTheme.backgroundSecondary,
              items: SoldierField.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label, style: TextStyle(color: AppTheme.textPrimary)),
                      ))
                  .toList(),
              onChanged: (f) {
                if (f == null) return;
                setState(() {
                  // Each field may be used by one column only.
                  if (f != SoldierField.ignore) {
                    for (var j = 0; j < _mapping.length; j++) {
                      if (_mapping[j] == f) _mapping[j] = SoldierField.ignore;
                    }
                  }
                  _mapping[i] = f;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
