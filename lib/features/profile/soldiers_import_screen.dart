import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/soldier_import_service.dart';
import 'package:chopel_app/core/services/spreadsheet_picker.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';

/// 3 steps: pick file (or paste table) -> map columns -> preview & save.
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

  void _applyLoadedTable(ImportTable table, String sourceLabel) {
    if (!mounted) return;
    setState(() {
      _table = table;
      _fileName = sourceLabel;
      _mapping = SoldierImportService.smartGuessMapping(table);
    });
  }

  Future<void> _pickFile({bool allowAnyFile = false}) async {
    try {
      final file = await SpreadsheetPicker.pick(allowAnyFile: allowAnyFile);
      if (file == null) return;
      final table = SoldierImportService.parse(file.bytes, file.name);
      _applyLoadedTable(table, file.name);
    } on FormatException catch (e) {
      if (mounted) HopalFeedback.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(
          context,
          AppErrorHelper.toHebrew(
            e,
            fallback: 'לא ניתן לקרוא את הקובץ שנבחר. ודא שמדובר בקובץ Excel (.xlsx) או CSV תקין.',
          ),
        );
      }
    }
  }

  Future<void> _openPasteSheet() async {
    final controller = TextEditingController();
    final resultText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacing16,
            right: AppTheme.spacing16,
            top: AppTheme.spacing16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppTheme.spacing24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.clipboard, color: AppTheme.primaryGreen, size: 22),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        'הדבקת טבלה מאקסל / Google Sheets',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'פתח את קובץ האקסל או Google Sheets בטלפון (גם מתוך וואטסאפ), סמן את התאים של החיילים, לחץ "העתק" והדבק כאן:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      try {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final txt = data?.text?.trim() ?? '';
                        if (txt.isEmpty) {
                          if (sheetCtx.mounted) {
                            HopalFeedback.showError(
                              sheetCtx,
                              'הלוח ריק או שהדפדפן חסם קריאה אוטומטית – לחץ לחיצה ארוכה בתיבה למטה ובחר "הדבק".',
                            );
                          }
                          return;
                        }
                        controller.text = txt;
                      } catch (_) {
                        if (sheetCtx.mounted) {
                          HopalFeedback.showError(
                            sheetCtx,
                            'לחץ לחיצה ארוכה בתוך התיבה למטה ובחר "הדבק".',
                          );
                        }
                      }
                    },
                    icon: Icon(LucideIcons.clipboard, size: 16, color: AppTheme.primaryGreen),
                    label: Text(
                      'הדבק אוטומטית מהלוח',
                      style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                TextField(
                  controller: controller,
                  minLines: 5,
                  maxLines: 9,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'לחץ לחיצה ארוכה כאן ובחר "הדבק"...\n\nדוגמה:\nשם מלא    מספר אישי    טלפון    מחלקה\nישראל ישראלי    8123456    050-1234567    1',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                    filled: true,
                    fillColor: AppTheme.backgroundPrimary,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.radiusMd,
                      borderSide: BorderSide(color: AppTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radiusMd,
                      borderSide: BorderSide(color: AppTheme.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.radiusMd,
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalButton(
                  label: 'המשך להתאמת עמודות',
                  icon: LucideIcons.check,
                  isExpanded: true,
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      HopalFeedback.showError(sheetCtx, 'יש להדביק תחילה את הטבלה בתיבה');
                      return;
                    }
                    Navigator.pop(sheetCtx, controller.text);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (resultText == null || resultText.trim().isEmpty) return;
    try {
      final table = SoldierImportService.parsePastedText(resultText);
      _applyLoadedTable(table, 'טבלה שהודבקה');
    } on FormatException catch (e) {
      if (mounted) HopalFeedback.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(
          context,
          AppErrorHelper.toHebrew(e, fallback: 'לא הצלחנו לפענח את הטקסט שהודבק.'),
        );
      }
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
      if (mounted) {
        HopalFeedback.showError(
          context,
          AppErrorHelper.toHebrew(e, fallback: 'שגיאה בשמירת רשימת החיילים בשרת.'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'ייבוא רשימת פלוגה',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileSpreadsheet, size: 64, color: AppTheme.primaryGreen),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'ייבוא חיילי הפלוגה',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'בחר קובץ אקסל מהמכשיר או הדבק ישירות את הטבלה מאקסל / Google Sheets / וואטסאפ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppTheme.spacing24),
            HopalButton(
              key: const Key('import_pick_file'),
              label: 'בחר קובץ אקסל / CSV מהמכשיר',
              icon: LucideIcons.upload,
              onPressed: () => _pickFile(allowAnyFile: false),
              isExpanded: true,
            ),
            const SizedBox(height: AppTheme.spacing12),
            HopalButton(
              key: const Key('import_paste_table'),
              label: 'הדבק טבלה מאקסל / Google Sheets',
              icon: LucideIcons.clipboard,
              variant: HopalButtonVariant.secondary,
              onPressed: _openPasteSheet,
              isExpanded: true,
            ),
            const SizedBox(height: AppTheme.spacing8),
            TextButton.icon(
              onPressed: () => _pickFile(allowAnyFile: true),
              icon: Icon(LucideIcons.folderOpen, size: 16, color: AppTheme.textSecondary),
              label: Text(
                'פתיחת סייר קבצים מלא (ללא סינון סיומות)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: AppTheme.radiusMd,
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.info, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'לא רואה קבצים בחלון שנפתח בטלפון?',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    '• באנדרואיד נפתח כברירת מחדל מסך "אחרונים" שמציג תמונות בלבד – לחץ על תפריט הצד (☰) בפינה העליונה ובחר "הורדות (Downloads)" או "הקבצים שלי".\n'
                    '• אם האקסל נשלח ב-WhatsApp: פתח אותו בוואטסאפ ⬅ לחץ על ⋮ ⬅ "שמור" כדי שיופיע בהורדות, או פשוט העתק את התאים והשתמש ב"הדבק טבלה" למעלה.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
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
                    child: Text(
                      '$_fileName • ${table.rows.length} שורות',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _table = null;
                      _fileName = null;
                      _mapping = [];
                    }),
                    child: const Text('שינוי מקור'),
                  ),
                ],
              ),
              if (table.allRows.length > 1)
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: SwitchListTile.adaptive(
                    dense: true,
                    activeTrackColor: AppTheme.primaryGreen,
                    title: Text(
                      'השורה הראשונה היא כותרות עמודות',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      table.firstRowIsHeader
                          ? 'כבה אם השורה הראשונה כבר מכילה חייל'
                          : 'כל השורות יייובאו כחיילים (ללא שורת כותרת)',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    value: table.firstRowIsHeader,
                    onChanged: (val) {
                      final updated = table.withHeaderMode(val);
                      setState(() {
                        _table = updated;
                        _mapping = SoldierImportService.smartGuessMapping(updated);
                      });
                    },
                  ),
                ),
              Text(
                'התאמת עמודות',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppTheme.spacing8),
              for (var i = 0; i < table.headers.length; i++) _buildMappingRow(i),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'תצוגה מקדימה (${preview.length} חיילים)',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppTheme.spacing8),
              if (!_hasName)
                Text(
                  'יש לסמן לפחות עמודת שם אחת',
                  style: TextStyle(color: AppTheme.criticalRed),
                ),
              ...preview.take(8).map(
                    (s) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.user, color: AppTheme.primaryGreen, size: 18),
                      title: Text(s.name, style: TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text(
                        [
                          if (s.personalNumber != null) 'מ.א ${s.personalNumber}',
                          if (s.phone != null) s.phone!,
                          if (s.platoon != null) 'מחלקה ${s.platoon}',
                          if (s.allergies != null) 'רגישות: ${s.allergies}',
                        ].join(' • '),
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  ),
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
                  Text(
                    table.headers[i].isEmpty ? 'עמודה ${i + 1}' : table.headers[i],
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  if (sample.isNotEmpty)
                    Text(
                      'לדוגמה: $sample',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            DropdownButton<SoldierField>(
              value: _mapping[i],
              underline: const SizedBox.shrink(),
              dropdownColor: AppTheme.backgroundSecondary,
              items: SoldierField.values
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label, style: TextStyle(color: AppTheme.textPrimary)),
                    ),
                  )
                  .toList(),
              onChanged: (f) {
                if (f == null) return;
                setState(() {
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
