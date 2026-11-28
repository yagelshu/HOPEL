import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_form_section.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_segmented_control.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_status_badge.dart';
import 'package:chopel_app/core/utils/platform_image.dart';
import 'package:chopel_app/core/utils/image_data_uri_helper.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/features/equipment/providers.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/features/medical_cases/widgets/inventory_dispense_sheet.dart';
import 'package:chopel_app/core/ai/medical_copilot_service.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/database/draft_service.dart';
import 'package:chopel_app/features/learning/medication_guide_screen.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalCaseCreateScreen extends ConsumerStatefulWidget {
  final MedicalCase? existingCase;
  final String? initialSoldierId;

  const MedicalCaseCreateScreen({super.key, this.existingCase, this.initialSoldierId});

  @override
  ConsumerState<MedicalCaseCreateScreen> createState() => _MedicalCaseCreateScreenState();
}

class _MedicalCaseCreateScreenState extends ConsumerState<MedicalCaseCreateScreen> {
  String? _selectedSoldierId;
  final _descController = TextEditingController();
  final _tempController = TextEditingController();
  final _hrController = TextEditingController();
  final _bpController = TextEditingController();
  final _spo2Controller = TextEditingController();

  String _selectedOutcome = 'COMPLETED';
  String _selectedCategory = 'שגרת מרפאה';
  String _selectedSeverity = 'שגרה';
  bool _addToMatabQueue = false;
  List<DispensedItem> _dispensedItems = [];

  bool _isSaving = false;
  bool _hasRestoredDraft = false;
  List<CasePhoto> _photos = [];
  final ImagePicker _picker = ImagePicker();

  static const String _fullDraftKey = 'medical_case_full_draft_v1';

  @override
  void initState() {
    super.initState();
    if (widget.existingCase != null) {
      _selectedSoldierId = widget.existingCase!.soldierId;
      _descController.text = widget.existingCase!.description ?? '';
      _selectedOutcome = widget.existingCase!.status;
      _selectedCategory = widget.existingCase!.category ?? 'שגרת מרפאה';
      _selectedSeverity = widget.existingCase!.severity ?? 'שגרה';
      _addToMatabQueue = BattalionStaffService.isCaseInMatabQueue(widget.existingCase!);
      _photos = List<CasePhoto>.from(widget.existingCase!.photos);
    } else {
      if (widget.initialSoldierId != null) {
        _selectedSoldierId = widget.initialSoldierId;
      }
      _loadDraft();
    }

    _descController.addListener(_saveDraft);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final fullRaw = prefs.getString(_fullDraftKey);
    if (fullRaw != null && fullRaw.isNotEmpty) {
      try {
        final map = jsonDecode(fullRaw) as Map<String, dynamic>;
        final savedDesc = map['description']?.toString() ?? '';
        final savedSoldierId = map['soldier_id']?.toString();
        if (savedDesc.trim().isNotEmpty || (savedSoldierId != null && savedSoldierId.isNotEmpty)) {
          if (!mounted) return;
          setState(() {
            if (widget.initialSoldierId == null && savedSoldierId != null && savedSoldierId.isNotEmpty) {
              _selectedSoldierId = savedSoldierId;
            }
            if (savedDesc.isNotEmpty) {
              _descController.text = savedDesc;
            }
            _selectedOutcome = map['outcome']?.toString() ?? _selectedOutcome;
            _selectedCategory = map['category']?.toString() ?? _selectedCategory;
            _selectedSeverity = map['severity']?.toString() ?? _selectedSeverity;
            _addToMatabQueue = map['add_to_matab_queue'] == true;
            _hasRestoredDraft = true;
          });
          return;
        }
      } catch (_) {}
    }

    final draft = prefs.getString('medical_case_draft');
    if (draft != null && draft.isNotEmpty && mounted) {
      setState(() {
        _descController.text = draft;
        _hasRestoredDraft = true;
      });
    }
  }

  Future<void> _saveDraft() async {
    if (widget.existingCase == null) {
      final prefs = await SharedPreferences.getInstance();
      final text = _descController.text;
      await prefs.setString('medical_case_draft', text);
      if (text.trim().isEmpty && _selectedSoldierId == null) {
        await prefs.remove(_fullDraftKey);
      } else {
        await prefs.setString(
          _fullDraftKey,
          jsonEncode({
            'soldier_id': _selectedSoldierId,
            'description': text,
            'outcome': _selectedOutcome,
            'category': _selectedCategory,
            'severity': _selectedSeverity,
            'add_to_matab_queue': _addToMatabQueue,
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );
      }
    }
  }

  Future<void> _clearDraftState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('medical_case_draft');
    await prefs.remove(_fullDraftKey);
    if (mounted) {
      setState(() {
        if (widget.initialSoldierId == null) {
          _selectedSoldierId = null;
        }
        _descController.clear();
        _selectedOutcome = 'COMPLETED';
        _selectedCategory = 'שגרת מרפאה';
        _selectedSeverity = 'שגרה';
        _addToMatabQueue = false;
        _dispensedItems = [];
        _photos = [];
        _hasRestoredDraft = false;
      });
    }
  }

  @override
  void dispose() {
    _descController.removeListener(_saveDraft);
    _descController.dispose();
    _tempController.dispose();
    _hrController.dispose();
    _bpController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  List<String> _computeVitalWarnings() {
    final warnings = <String>[];
    final temp = double.tryParse(_tempController.text.trim());
    if (temp != null) {
      if (temp >= 38.0) warnings.add('חום גבוה (${temp.toStringAsFixed(1)}°C)');
      if (temp < 35.0) warnings.add('תת-חום (${temp.toStringAsFixed(1)}°C)');
    }
    final hr = int.tryParse(_hrController.text.trim());
    if (hr != null) {
      if (hr > 100) warnings.add('דופק מהיר ($hr BPM)');
      if (hr < 50) warnings.add('דופק איטי ($hr BPM)');
    }
    final spo2 = int.tryParse(_spo2Controller.text.trim());
    if (spo2 != null && spo2 < 95) {
      warnings.add('סטורציה נמוכה ($spo2%)');
    }
    final bpText = _bpController.text.trim();
    if (bpText.contains('/')) {
      final sys = int.tryParse(bpText.split('/').first.trim());
      if (sys != null) {
        if (sys < 90) warnings.add('ל"ד סיסטולי נמוך ($bpText)');
        if (sys >= 140) warnings.add('ל"ד גבוה ($bpText)');
      }
    }
    return warnings;
  }

  String _formatVitalsSummary() {
    final parts = <String>[];
    final temp = _tempController.text.trim();
    if (temp.isNotEmpty) {
      final tVal = double.tryParse(temp);
      final flag = (tVal != null && (tVal >= 38.0 || tVal < 35.0)) ? ' ⚠️' : '';
      parts.add('חום $temp°C$flag');
    }
    final hr = _hrController.text.trim();
    if (hr.isNotEmpty) {
      final hVal = int.tryParse(hr);
      final flag = (hVal != null && (hVal > 100 || hVal < 50)) ? ' ⚠️' : '';
      parts.add('דופק $hr$flag');
    }
    final bp = _bpController.text.trim();
    if (bp.isNotEmpty) {
      parts.add('ל"ד $bp');
    }
    final spo2 = _spo2Controller.text.trim();
    if (spo2.isNotEmpty) {
      final sVal = int.tryParse(spo2);
      final flag = (sVal != null && sVal < 95) ? ' ⚠️' : '';
      parts.add('סטורציה $spo2%$flag');
    }
    if (parts.isEmpty) return '';
    return '📊 מדדים: ${parts.join(' | ')}';
  }

  final List<String> _quickTags = [
    'שפשפות',
    'חום/צינון',
    'כאבי גרון',
    'כאבי בטן/שלשולים',
    'כאב ראש',
    'כאבי גב/ברכיים',
    'נקע/חבלה',
    'פטרת/פריחה',
    'טראומה',
    'בקשת תור לרופא',
    'הוצאת גימלים',
  ];

  final List<Map<String, String>> _clinicalPresets = const [
    {
      'title': 'כאב גרון / צינון',
      'text': 'מתלונן על כאב גרון וגודש באף. בבדיקה: ללא קושי בבליעת רוק או פתיחת פה, ללא קוצר נשימה. הונחה לשתייה מרובה ומנוחה.',
    },
    {
      'title': 'גסטרו / שלשולים',
      'text': 'מתלונן על שלשולים וכאבי בטן. בבדיקה: ללא דם בצואה, ללא הקאות בלתי פוסקות, בטן רכה ללא גירוי צפקי, ריריות לחות. הונחה לשתייה מרובה.',
    },
    {
      'title': 'כאב גב / שרירים',
      'text': 'מתלונן על כאב גב/שרירים לאחר מאמץ. בבדיקה: ללא חבלה ישירה, ללא הקרנה לגפיים או חסר נוירולוגי, תנועה שמורה.',
    },
    {
      'title': 'שפשפת / גירוי עורי',
      'text': 'גירוי עורי ואודם מקומי באזור המפשעה/ירכיים. ללא סימני זיהום משני או הפרשה מוגלתית. הונחה להיגיינה מקומית ומריחת משחה.',
    },
    {
      'title': 'כאב ראש / עייפות',
      'text': 'מתלונן על כאב ראש כללי. בבדיקה: בהכרה מלאה, ללא קשיון עורף, ללא הפרעות ראייה או הקאות, שלל חבלת ראש. הונחה לשתייה ומנוחה.',
    },
    {
      'title': 'חבלה קלה / שפשוף',
      'text': 'פציעה שטחית בגפה. בוצעה שטיפה וחיטוי מקומי, חבישה נקייה. טטנוס בתוקף, תחושה ותנועה שמורות.',
    },
  ];

  void _applyClinicalPreset(Map<String, String> preset) {
    final text = preset['text'] ?? '';
    if (text.isEmpty) return;
    final current = _descController.text.trim();
    if (current.isEmpty) {
      _descController.text = text;
    } else if (!current.contains(text)) {
      _descController.text = '$current\n$text';
    }
    _saveDraft();
  }

  void _addTag(String tag) {
    final current = _descController.text;
    if (current.isEmpty) {
      _descController.text = tag;
    } else {
      _descController.text = '$current, $tag';
    }
    if (tag == 'בקשת תור לרופא') {
      setState(() {
        _selectedOutcome = 'REQUIRES_ATTENTION';
        _selectedSeverity = 'דחוף';
        _addToMatabQueue = true;
        _selectedCategory = BattalionStaffService.matabCategory;
      });
    }
    _saveDraft();
  }

  Future<String?> _askComplaintTag({String? currentTag, String? imageUri}) async {
    final customController = TextEditingController(text: currentTag ?? '');
    String? selected = currentTag;

    final tags = <String>{
      ..._quickTags,
      if (currentTag != null && currentTag.isNotEmpty) currentTag,
    }.toList();

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppTheme.spacing24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.tag, color: AppTheme.primaryGreen, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'שיוך תמונה לסוג התלונה',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(sheetContext, selected),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'בחר לאיזו תלונה רפואית שייך צילום זה (או הקלד תיאור קצר):',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    if (imageUri != null) ...[
                      Center(
                        child: ClipRRect(
                          borderRadius: AppTheme.radiusMd,
                          child: Container(
                            height: 100,
                            width: 140,
                            color: AppTheme.backgroundPrimary,
                            child: Image(
                              image: resolveLocalOrWebImage(imageUri),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(LucideIcons.image, color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final isSelected = selected == tag;
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              selected = isSelected ? null : tag;
                              customController.text = selected ?? '';
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.backgroundPrimary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected ? AppTheme.onPrimaryGreen : AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    HopalTextField(
                      controller: customController,
                      hint: 'או הקלד סוג תלונה מותאם אישית...',
                      icon: LucideIcons.pencil,
                      onChanged: (val) {
                        setSheetState(() {
                          selected = val.trim().isEmpty ? null : val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: AppTheme.borderSubtle),
                              shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                            ),
                            onPressed: () => Navigator.pop(sheetContext, null),
                            child: Text('ללא שיוך', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: HopalButton(
                            label: 'אישור שיוך',
                            icon: LucideIcons.check,
                            onPressed: () {
                              final finalTag = customController.text.trim();
                              Navigator.pop(sheetContext, finalTag.isNotEmpty ? finalTag : selected);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  Future<void> _pickImage() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(LucideIcons.camera, color: AppTheme.primaryGreen),
                title: Text('צלם תמונה במצלמה', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: Text('דחיסה אוטומטית ואיכות שטח אופטימלית', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(LucideIcons.images, color: AppTheme.infoBlue),
                title: Text('בחר תמונות מהגלריה (אפשרות לבחירה מרובה)', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: Text('העלאת מספר תמונות יחד בדחיסה מהירה', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () => Navigator.pop(context, 'multi_gallery'),
              ),
            ],
          ),
        );
      },
    );

    if (mode == null) return;

    try {
      if (mode == 'camera') {
        final res = await ImageDataUriHelper.pickAsDataUriWithResult(_picker, ImageSource.camera);
        if (res != null && mounted) {
          final tag = await _askComplaintTag(imageUri: res.dataUri);
          if (mounted) {
            setState(() {
              _photos.add(CasePhoto(path: res.dataUri, complaintTag: tag));
            });
            HopalFeedback.showInfo(context, 'התמונה נדחסה בהצלחה (${res.sizeLabel})');
          }
        }
      } else if (mode == 'multi_gallery') {
        final list = await ImageDataUriHelper.pickMultipleAsDataUri(_picker);
        if (list.isNotEmpty && mounted) {
          int addedCount = 0;
          int totalKb = 0;
          for (final res in list) {
            if (!mounted) break;
            final tag = await _askComplaintTag(imageUri: res.dataUri);
            if (mounted) {
              setState(() {
                _photos.add(CasePhoto(path: res.dataUri, complaintTag: tag));
              });
              addedCount++;
              totalKb += res.kb;
            }
          }
          if (mounted && addedCount > 0) {
            HopalFeedback.showInfo(context, '$addedCount תמונות נדחסו ונוספו בהצלחה ($totalKb KB סה"כ)');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        HopalFeedback.showError(context, 'שגיאה בטעינת התמונה');
      }
    }
  }

  Future<void> _editPhotoTag(int index) async {
    if (index < 0 || index >= _photos.length) return;
    final current = _photos[index];
    final newTag = await _askComplaintTag(currentTag: current.complaintTag, imageUri: current.path);
    if (mounted) {
      setState(() {
        _photos[index] = current.copyWith(complaintTag: newTag, clearTag: newTag == null);
      });
    }
  }

  void _showAddSoldierDialog() {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final phoneController = TextEditingController();
    final platoonController = TextEditingController();
    final allergiesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundSecondary,
          title: Text('הוספת חייל חדש', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HopalTextField(
                  controller: nameController,
                  hint: 'שם מלא (לדוגמה: ישראל ישראלי) *',
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalTextField(
                  controller: idController,
                  hint: 'מספר אישי *',
                  icon: LucideIcons.hash,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalTextField(
                  controller: phoneController,
                  hint: 'טלפון (אופציונלי)',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalTextField(
                  controller: platoonController,
                  hint: 'מחלקה (לדוגמה: מחלקה 1 / חפ"ק / מסופחים)',
                  icon: LucideIcons.shield,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: PlatoonHelper.quickSelectPlatoons.map((plt) {
                    return ActionChip(
                      label: Text(plt, style: const TextStyle(fontSize: 11)),
                      backgroundColor: plt == 'מסופחים'
                          ? AppTheme.infoBlue.withValues(alpha: 0.16)
                          : AppTheme.backgroundTertiary,
                      side: plt == 'מסופחים'
                          ? BorderSide(color: AppTheme.infoBlue.withValues(alpha: 0.45))
                          : null,
                      onPressed: () {
                        platoonController.text = plt;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacing16),
                HopalTextField(
                  controller: allergiesController,
                  hint: 'אלרגיות / רגישויות (G6PD, פניצילין וכו\')',
                  icon: LucideIcons.alertTriangle,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: ['G6PD', 'פניצילין', 'אופטלגין', 'NSAID'].map((alg) {
                    return ActionChip(
                      label: Text(alg, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppTheme.backgroundTertiary,
                      onPressed: () {
                        final current = allergiesController.text.trim();
                        allergiesController.text = current.isEmpty ? alg : '$current, $alg';
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.onPrimaryGreen,
              ),
              onPressed: () async {
                final rawName = nameController.text.trim();
                final personalNum = idController.text.trim();
                final phone = phoneController.text.trim();
                final platoon = platoonController.text.trim();
                final allergies = allergiesController.text.trim();

                if (rawName.isEmpty || personalNum.isEmpty) {
                  HopalFeedback.showError(context, 'נא למלא שם ומספר אישי');
                  return;
                }

                final user = AuthService().currentUser;
                final soldierId = const Uuid().v4();

                final payload = <String, dynamic>{
                  'id': soldierId,
                  'name': rawName,
                  'personal_number': personalNum,
                  'unit_id': user?.unitId,
                  if (phone.isNotEmpty) 'phone_number': phone,
                  if (platoon.isNotEmpty) 'platoon': platoon,
                  if (allergies.isNotEmpty) 'allergies': allergies,
                };

                try {
                  try {
                    await Supabase.instance.client.from('soldiers').insert(payload);
                  } on PostgrestException catch (pe) {
                    if (pe.code == 'PGRST204' ||
                        pe.code == '42703' ||
                        pe.message.contains('allergies') ||
                        pe.message.contains('personal_number')) {
                      payload.remove('allergies');
                      final fallbackPayload = <String, dynamic>{
                        'id': soldierId,
                        'name': personalNum.isNotEmpty ? '$rawName ($personalNum)' : rawName,
                        'unit_id': user?.unitId,
                        if (phone.isNotEmpty) 'phone_number': phone,
                        if (platoon.isNotEmpty) 'platoon': platoon,
                      };
                      await Supabase.instance.client.from('soldiers').insert(fallbackPayload);
                    } else {
                      rethrow;
                    }
                  }

                  if (!context.mounted) return;
                  ref.invalidate(soldiersProvider);
                  Navigator.pop(context);
                  setState(() {
                    _selectedSoldierId = soldierId;
                  });
                  HopalFeedback.showSuccess(context, 'חייל נוסף בהצלחה');
                } catch (e) {
                  if (context.mounted) {
                    HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה בהוספת החייל. נסה שוב.'));
                  }
                }
              },
              child: const Text('הוסף חייל', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openSoldierSearchSheet(List<Soldier> soldiers) {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';
        String selectedPlatoon = 'הכל';

        final platoons = PlatoonHelper.extractPlatoons(soldiers, (s) => s.platoon);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = searchQuery.trim().toLowerCase();
            final cleanQ = q.replaceAll(RegExp(r'[\s-]'), '');
            final filtered = soldiers.where((s) {
              final cleanPn = (s.personalNumber ?? '').replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
              final matchesQuery = q.isEmpty ||
                  s.name.toLowerCase().contains(q) ||
                  (cleanPn.isNotEmpty && cleanPn.contains(cleanQ)) ||
                  (s.phoneNumber != null && s.phoneNumber!.contains(cleanQ)) ||
                  (s.platoon != null && s.platoon!.toLowerCase().contains(q));
              final matchesPlatoon = selectedPlatoon == 'הכל' || PlatoonHelper.matches(s.platoon, selectedPlatoon);
              return matchesQuery && matchesPlatoon;
            }).toList();
            filtered.sort((a, b) => a.name.compareTo(b.name));

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                top: AppTheme.spacing16,
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('בחירת חייל מהפלוגה',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.userPlus, size: 16),
                        label: const Text('חייל חדש'),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddSoldierDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    style: TextStyle(color: AppTheme.textPrimary),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'הקלד שם, מספר אישי או מחלקה...',
                      prefixIcon: Icon(LucideIcons.search, color: AppTheme.textSecondary),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                              tooltip: 'נקה חיפוש',
                              onPressed: () {
                                searchController.clear();
                                setModalState(() => searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.backgroundTertiary,
                      border: const OutlineInputBorder(borderRadius: AppTheme.radiusMd, borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (platoons.length > 2) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: platoons.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final p = platoons[i];
                          final isSel = selectedPlatoon == p;
                          return ChoiceChip(
                            label: Text(p),
                            selected: isSel,
                            checkmarkColor: AppTheme.onPrimaryGreen,
                            onSelected: (_) => setModalState(() => selectedPlatoon = p),
                            selectedColor: AppTheme.primaryGreen,
                            backgroundColor: AppTheme.backgroundTertiary,
                            labelStyle: TextStyle(
                              color: isSel ? AppTheme.onPrimaryGreen : AppTheme.textSecondary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.userX, size: 40, color: AppTheme.textSecondary),
                                const SizedBox(height: 8),
                                Text('לא נמצא חייל תואם', style: TextStyle(color: AppTheme.textSecondary)),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    foregroundColor: AppTheme.onPrimaryGreen,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showAddSoldierDialog();
                                  },
                                  icon: const Icon(LucideIcons.userPlus, size: 16),
                                  label: const Text('הוסף חייל חדש עכשיו', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final s = filtered[index];
                              final hasPn = s.personalNumber != null && s.personalNumber!.isNotEmpty;
                              final hasPlatoon = s.platoon != null && s.platoon!.isNotEmpty;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: s.hasAllergies
                                      ? AppTheme.criticalRed.withValues(alpha: 0.15)
                                      : AppTheme.primaryGreen.withValues(alpha: 0.15),
                                  child: Icon(
                                    s.hasAllergies ? LucideIcons.alertTriangle : LucideIcons.user,
                                    color: s.hasAllergies ? AppTheme.criticalRed : AppTheme.primaryGreen,
                                  ),
                                ),
                                title: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(s.name,
                                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    if (s.hasAllergies)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.criticalRed.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          'רגישות: ${s.allergies}',
                                          style: TextStyle(fontSize: 10, color: AppTheme.criticalRed, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  [
                                    if (hasPn) 'מ.א: ${s.personalNumber}',
                                    if (hasPlatoon) PlatoonHelper.formatDisplay(s.platoon),
                                    if (s.phoneNumber != null) s.phoneNumber!,
                                  ].join(' • '),
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                onTap: () {
                                  setState(() => _selectedSoldierId = s.id);
                                  _saveDraft();
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  Future<void> _runCopilot() async {
    final complaint = _descController.text.trim();
    if (complaint.isEmpty) {
      HopalFeedback.showError(context, 'נא להזין או לבחור תלונות תחילה');
      return;
    }

    final soldiers = ref.read(soldiersProvider).maybeWhen(
          data: (list) => list,
          orElse: () => <Soldier>[],
        );
    final selectedSoldier = soldiers.where((s) => s.id == _selectedSoldierId).firstOrNull;
    final soldierAllergies = selectedSoldier?.allergies;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: MedicalCopilotService().analyzeSymptoms(
            complaint,
            allergies: soldierAllergies,
          ),
          builder: (context, snapshot) {
            final warnings = List<String>.from(snapshot.data?['allergyWarnings'] as List? ?? const []);
            final redFlags = List<String>.from(snapshot.data?['redFlags'] as List? ?? const []);
            final medications = List<String>.from(snapshot.data?['medications'] as List? ?? const []);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.stethoscope, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'עזר החלטה קליני והצלבת רגישויות',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                    else if (snapshot.hasError)
                      Text('שגיאה בניתוח התלונה: ${snapshot.error}', style: TextStyle(color: AppTheme.warningAmber))
                    else if (snapshot.hasData) ...[
                      if (warnings.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spacing12),
                          margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: AppTheme.criticalRed.withValues(alpha: 0.14),
                            borderRadius: AppTheme.radiusMd,
                            border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.65)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.shieldAlert, color: AppTheme.criticalRed, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'התראת בטיחות ורגישויות',
                                    style: TextStyle(
                                      color: AppTheme.criticalRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...warnings.map(
                                (w) => Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text('• $w', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Text('אבחנה משוערת:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      Text(snapshot.data!['diagnosis'].toString(), style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                      const SizedBox(height: AppTheme.spacing16),
                      Text('המלצת טיפול:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      Text(snapshot.data!['treatment'].toString(), style: TextStyle(color: AppTheme.textPrimary, height: 1.4)),
                      const SizedBox(height: AppTheme.spacing16),
                      if (redFlags.isNotEmpty) ...[
                        Text('דגלים אדומים (סכנה):', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningAmber)),
                        const SizedBox(height: 4),
                        ...redFlags.map((flag) => Text('• $flag', style: TextStyle(color: AppTheme.textPrimary))),
                        const SizedBox(height: AppTheme.spacing16),
                      ],
                      if (medications.isNotEmpty) ...[
                        Text('תרופות מתאימות מארגז חופ"ל:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.infoBlue)),
                        const SizedBox(height: 4),
                        ...medications.map((med) => Text('• $med', style: TextStyle(color: AppTheme.textPrimary))),
                      ] else if (warnings.isNotEmpty) ...[
                        Text(
                          'כל התרופות שנשקלו סומנו לבדיקה חוזרת עקב רגישויות החייל — יש להיוועץ ברופא.',
                          style: TextStyle(color: AppTheme.warningAmber, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacing24),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDispensePicker() async {
    final allEquipment = ref.read(equipmentProvider).value ?? [];
    final soldiers = ref.read(soldiersProvider).value ?? [];
    final selectedSoldier = soldiers.where((s) => s.id == _selectedSoldierId).firstOrNull;
    final picked = await InventoryDispenseHelper.showPickerSheet(
      context,
      allEquipment: allEquipment,
      initialSelection: _dispensedItems,
      soldierName: selectedSoldier?.name,
      soldierAllergies: selectedSoldier?.allergies,
    );
    if (picked != null && mounted) {
      setState(() {
        _dispensedItems = picked;
      });
    }
  }

  Future<void> _deductDispensedItems() async {
    if (_dispensedItems.isEmpty) return;
    final notifier = ref.read(equipmentProvider.notifier);
    for (final item in _dispensedItems) {
      if (item.quantity > 0) {
        await notifier.adjustQuantity(item.equipmentId, -item.quantity);
      }
    }
  }

  Future<void> _handleCreate() async {
    if (_selectedSoldierId == null) {
      HopalFeedback.showError(context, 'יש לבחור חייל');
      return;
    }

    if (_descController.text.trim().isEmpty) {
      HopalFeedback.showError(context, 'יש להזין תיאור / אבחנה רפואית');
      return;
    }

    setState(() => _isSaving = true);

    String finalDescription = _descController.text.trim();
    final vitalsLine = _formatVitalsSummary();
    if (vitalsLine.isNotEmpty && !finalDescription.contains(vitalsLine)) {
      finalDescription = '$finalDescription\n$vitalsLine';
    }
    final dispensedLine = InventoryDispenseHelper.formatDispensedSummary(_dispensedItems);
    if (dispensedLine.isNotEmpty && !finalDescription.contains(dispensedLine)) {
      finalDescription = '$finalDescription\n$dispensedLine';
    }

    if (widget.existingCase == null && !finalDescription.contains('🩺 תועד ע"י:')) {
      final medicName = AuthService().effectiveUserName.trim();
      final medicPlatoon = AuthService().effectiveUserPlatoon?.trim();
      final roleLabel = AuthService().isCompanyMedic
          ? 'חופ"ל'
          : (medicPlatoon != null && medicPlatoon.isNotEmpty ? 'חובש $medicPlatoon' : 'חובש');
      finalDescription = '$finalDescription\n🩺 תועד ע"י: $medicName ($roleLabel)';
    }

    final effectiveCategory = (_selectedOutcome != 'COMPLETED' && _addToMatabQueue)
        ? BattalionStaffService.matabCategory
        : (_selectedCategory == BattalionStaffService.matabCategory && !_addToMatabQueue
            ? 'שגרת מרפאה'
            : _selectedCategory);

    final payload = {
      'soldier_id': _selectedSoldierId,
      'status': _selectedOutcome,
      'description': finalDescription,
      'category': effectiveCategory,
      'severity': _selectedSeverity,
      'updated_date': DateTime.now().toIso8601String(),
      'image_path': MedicalCase.encodePhotos(_photos),
    };

    try {
      if (widget.existingCase == null) {
        payload['id'] = const Uuid().v4();
        payload['created_date'] = DateTime.now().toIso8601String();
        payload['deployment_id'] = AuthService().currentUser?.activeDeploymentId;
        await Supabase.instance.client.from('medical_cases').insert(payload);
      } else {
        await Supabase.instance.client.from('medical_cases').update(payload).eq('id', widget.existingCase!.id);
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isNetworkError = errStr.contains('socketexception') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('clientexception') ||
          errStr.contains('timeout') ||
          errStr.contains('network') ||
          errStr.contains('connection refused') ||
          errStr.contains('os error') ||
          errStr.contains('offline');

      if (isNetworkError) {
        if (widget.existingCase != null) {
          if (mounted) HopalFeedback.showError(context, 'עריכת תיק רפואי דורשת חיבור זמין לאינטרנט');
          setState(() => _isSaving = false);
          return;
        }
        await DraftService.saveDraft(payload);
        await _deductDispensedItems();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('medical_case_draft');
        await prefs.remove(_fullDraftKey);
        if (mounted) {
          HopalFeedback.showSuccess(context, 'אין קליטה - התיק והמלאי עודכנו בטלפון ויסונכרנו בהמשך');
          Navigator.pop(context);
        }
        return;
      }
      if (mounted) HopalFeedback.showError(context, AppErrorHelper.toHebrew(e, fallback: 'שגיאה בשמירת התיק הרפואי. נסה שוב.'));
      setState(() => _isSaving = false);
      return;
    }

    await _deductDispensedItems();

    if (!mounted) return;

    if (widget.existingCase == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('medical_case_draft');
      await prefs.remove(_fullDraftKey);
      if (!mounted) return;
    }

    // Refresh the list providers
    ref.read(medicalCasesProvider.notifier).refresh();
    ref.invalidate(dashboardMetricsProvider);

    HopalFeedback.showSuccess(
      context,
      _dispensedItems.isNotEmpty
          ? 'הפנייה נשמרה והציוד שנופק הופחת אוטומטית מהמלאי'
          : (widget.existingCase == null ? 'הפנייה הרפואית נפתחה בהצלחה' : 'הפנייה הרפואית עודכנה בהצלחה'),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final soldiersAsync = ref.watch(soldiersProvider);
    ref.watch(equipmentProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              widget.existingCase == null ? 'פנייה חדשה' : 'עריכת פנייה',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
            ),
            backgroundColor: AppTheme.backgroundPrimary,
            elevation: 0,
            centerTitle: true,
            pinned: true,
            floating: true,
            leading: IconButton(
              icon: Icon(LucideIcons.x, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_hasRestoredDraft && widget.existingCase == null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withValues(alpha: 0.14),
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.history, size: 18, color: AppTheme.infoBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'שוחזרה טיוטה שנשמרה אוטומטית מהפנייה הקודמת',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppTheme.criticalRed,
                          ),
                          onPressed: _clearDraftState,
                          child: const Text('נקה טיוטה', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                ],
                HopalFormSection(
                  title: 'חייל מטופל',
                  children: [
                    soldiersAsync.when(
                      data: (soldiers) {
                        final soldier = soldiers.where((s) => s.id == _selectedSoldierId).firstOrNull;

                        if (soldier != null) {
                          final hasPhone = soldier.phoneNumber != null && soldier.phoneNumber!.trim().isNotEmpty;
                          return Container(
                            padding: const EdgeInsets.all(AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: AppTheme.radiusMd,
                              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                      child: Icon(LucideIcons.userCheck, color: AppTheme.primaryGreen),
                                    ),
                                    const SizedBox(width: AppTheme.spacing12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(soldier.name,
                                              style: TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              if (soldier.personalNumber != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.backgroundTertiary,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('מ.א: ${soldier.personalNumber}',
                                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                                ),
                                              if (soldier.platoon != null && soldier.platoon!.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(PlatoonHelper.formatDisplay(soldier.platoon),
                                                      style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                          if (soldier.hasAllergies) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.criticalRed.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.5)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(LucideIcons.alertTriangle, size: 14, color: AppTheme.criticalRed),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'רגישות רפואית: ${soldier.allergies}',
                                                      style: TextStyle(fontSize: 12, color: AppTheme.criticalRed, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(LucideIcons.refreshCw, color: AppTheme.textSecondary, size: 18),
                                      tooltip: 'החלף חייל',
                                      onPressed: () => _openSoldierSearchSheet(soldiers),
                                    ),
                                    IconButton(
                                      icon: Icon(LucideIcons.x, color: AppTheme.criticalRed, size: 18),
                                      tooltip: 'נקה בחירה',
                                      onPressed: () => setState(() => _selectedSoldierId = null),
                                    ),
                                  ],
                                ),
                                if (hasPhone) ...[
                                  const SizedBox(height: 12),
                                  Divider(color: AppTheme.borderSubtle, height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.phone, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(soldier.phoneNumber!,
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                      const Spacer(),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        icon: Icon(LucideIcons.phoneCall, size: 14, color: AppTheme.primaryGreen),
                                        label: Text('חייג', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                                        onPressed: () async {
                                          final uri = Uri.parse('tel:${soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '')}');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                                        },
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        icon: Icon(LucideIcons.messageCircle, size: 14, color: AppTheme.successGreen),
                                        label: Text('WhatsApp', style: TextStyle(color: AppTheme.successGreen, fontSize: 12)),
                                        onPressed: () async {
                                          var phone = soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '');
                                          if (phone.startsWith('0')) phone = '972${phone.substring(1)}';
                                          final uri = Uri.parse('https://wa.me/$phone');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          onTap: () => _openSoldierSearchSheet(soldiers),
                          borderRadius: AppTheme.radiusMd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: AppTheme.radiusMd,
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  child: Icon(LucideIcons.userSearch, color: AppTheme.primaryGreen),
                                ),
                                const SizedBox(width: AppTheme.spacing16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('בחר חייל מהפלוגה...',
                                          style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text('חיפוש מהיר לפי שם, מספר אישי או מחלקה (${soldiers.length} חיילים זמינים)',
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(LucideIcons.chevronDown, color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Text('שגיאה בטעינת חיילים'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24),

                HopalFormSection(
                  title: 'תגיות מהירות (הזנה ללא הקלדה)',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickTags.map((tag) {
                        return InkWell(
                          onTap: () => _addTag(tag),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              border: Border.all(color: AppTheme.primaryGreen),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(color: AppTheme.onPrimaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Row(
                      children: [
                        Icon(LucideIcons.wandSparkles, size: 15, color: AppTheme.infoBlue),
                        const SizedBox(width: 6),
                        Text(
                          'מילוי אנמנזה מהיר (לפי תלונה נפוצה):',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _clinicalPresets.map((preset) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ActionChip(
                              avatar: Icon(LucideIcons.clipboardCheck, size: 14, color: AppTheme.infoBlue),
                              label: Text(
                                preset['title']!,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppTheme.backgroundSecondary,
                              side: BorderSide(color: AppTheme.infoBlue.withValues(alpha: 0.4)),
                              onPressed: () => _applyClinicalPreset(preset),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    HopalTextField(
                      controller: _descController,
                      hint: 'תיאור מילולי חופשי (אופציונלי)...',
                      icon: LucideIcons.fileText,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Row(
                      children: [
                        Icon(LucideIcons.activity, size: 15, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Text(
                          'מדדים חיוניים מהירים (אופציונלי – מזהה חריגה אוטומטית):',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tempController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'חום °C',
                              hintText: '36.8',
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.backgroundSecondary,
                              border: const OutlineInputBorder(borderRadius: AppTheme.radiusSm),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _hrController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'דופק',
                              hintText: '75',
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.backgroundSecondary,
                              border: const OutlineInputBorder(borderRadius: AppTheme.radiusSm),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _bpController,
                            keyboardType: TextInputType.datetime,
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'ל"ד',
                              hintText: '120/80',
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.backgroundSecondary,
                              border: const OutlineInputBorder(borderRadius: AppTheme.radiusSm),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _spo2Controller,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'סטורציה %',
                              hintText: '98',
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.backgroundSecondary,
                              border: const OutlineInputBorder(borderRadius: AppTheme.radiusSm),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        final vitalWarnings = _computeVitalWarnings();
                        if (vitalWarnings.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.criticalRed.withValues(alpha: 0.14),
                              borderRadius: AppTheme.radiusMd,
                              border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.alertTriangle, size: 16, color: AppTheme.criticalRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'מדד חריג: ${vitalWarnings.join(', ')}',
                                    style: TextStyle(
                                      color: AppTheme.criticalRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!_addToMatabQueue)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: AppTheme.primaryGreen,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedOutcome = 'REQUIRES_ATTENTION';
                                        _selectedSeverity = 'דחוף';
                                        _addToMatabQueue = true;
                                        _selectedCategory = BattalionStaffService.matabCategory;
                                      });
                                    },
                                    child: const Text('שבץ למט"ב', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    if (_photos.isEmpty)
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: AppTheme.radiusMd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundSecondary,
                            border: Border.all(
                              color: AppTheme.borderSubtle,
                              width: 1.5,
                            ),
                            borderRadius: AppTheme.radiusMd,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.camera, color: AppTheme.primaryGreen),
                              const SizedBox(width: AppTheme.spacing8),
                              Text('הוסף צילום רפואי ושייך לתלונה (אופציונלי)',
                                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.images, color: AppTheme.primaryGreen, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'צילומים רפואיים שצורפו (${_photos.length}):',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _pickImage,
                                icon: Icon(LucideIcons.plus, size: 14, color: AppTheme.primaryGreen),
                                label: Text(
                                  'הוסף צילום',
                                  style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 175,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _photos.length + 1,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, idx) {
                                if (idx == _photos.length) {
                                  // Add new photo button card
                                  return InkWell(
                                    onTap: _pickImage,
                                    borderRadius: AppTheme.radiusMd,
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundSecondary,
                                        borderRadius: AppTheme.radiusMd,
                                        border: Border.all(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                                          style: BorderStyle.solid,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(LucideIcons.camera, color: AppTheme.primaryGreen, size: 22),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'הוסף צילום',
                                            style: TextStyle(
                                              color: AppTheme.primaryGreen,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final photo = _photos[idx];
                                return Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundSecondary,
                                    borderRadius: AppTheme.radiusMd,
                                    border: Border.all(color: AppTheme.borderSubtle),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: AppTheme.radiusMd,
                                        child: Image(
                                          image: resolveLocalOrWebImage(photo.path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(LucideIcons.imageOff, color: AppTheme.textMuted, size: 28),
                                          ),
                                        ),
                                      ),
                                      // Complaint Tag Chip (Clickable to edit tag)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        left: 6,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _editPhotoTag(idx),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (photo.complaintTag != null && photo.complaintTag!.isNotEmpty)
                                                    ? AppTheme.primaryGreen.withValues(alpha: 0.9)
                                                    : Colors.black.withValues(alpha: 0.75),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    photo.complaintTag != null ? LucideIcons.tag : LucideIcons.pencil,
                                                    color: Colors.white,
                                                    size: 11,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      photo.complaintTag ?? '+ שייך תלונה',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Remove button
                                      Positioned(
                                        bottom: 6,
                                        left: 6,
                                        child: Material(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(16),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () => setState(() => _photos.removeAt(idx)),
                                            child: const Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Icon(LucideIcons.trash2, color: Colors.white, size: 14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppTheme.spacing16),
                    HopalButton(
                      label: 'הפק הנחיות טיפול והצלבת רגישויות',
                      icon: LucideIcons.stethoscope,
                      onPressed: _runCopilot,
                      isExpanded: true,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                        shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      icon: const Icon(LucideIcons.pill, size: 18),
                      label: const Text('מדריך תרופות שטח ומחשבון מינונים', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MedicationGuideScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24),

                HopalCard(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.packageMinus, color: AppTheme.primaryGreen, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ניפוק תרופה / ציוד מהמלאי (הורדה אוטומטית)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'בחר תרופות או ציוד שניתנו לחייל כדי להפחיתם אוטומטית מהארגז או מהווסט ולתעדם בתיק:',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      if (_dispensedItems.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dispensedItems.map((item) {
                            return Chip(
                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                              side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                              label: Text(
                                '${item.name} (x${item.quantity}) • ${item.sourceLabel}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              deleteIcon: Icon(LucideIcons.x, size: 14, color: AppTheme.textSecondary),
                              onDeleted: () {
                                setState(() {
                                  _dispensedItems.removeWhere((e) => e.equipmentId == item.equipmentId);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                          shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                        ),
                        icon: const Icon(LucideIcons.plusCircle, size: 17),
                        label: Text(
                          _dispensedItems.isEmpty
                              ? 'בחר תרופה / ציוד לניפוק מהמלאי'
                              : 'ערוך פריטים שנופקו (${_dispensedItems.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _openDispensePicker,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacing20),

                HopalCard(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('סטטוס הפנייה', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          HopalStatusBadge(
                            label: _selectedOutcome == 'COMPLETED' ? 'הטיפול הושלם' : 'דורש המשך טיפול / מט"ב',
                            variant: _selectedOutcome == 'COMPLETED' ? HopalStatusBadgeVariant.neutral : HopalStatusBadgeVariant.warning,
                            icon: _selectedOutcome == 'COMPLETED' ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      HopalSegmentedControl(
                        segments: const ['הטיפול הושלם במקום', 'נדרש המשך מעקב / מט"ב'],
                        selectedIndex: _selectedOutcome == 'COMPLETED' ? 0 : 1,
                        onValueChanged: (index) {
                          setState(() {
                            _selectedOutcome = index == 0 ? 'COMPLETED' : 'REQUIRES_ATTENTION';
                            _selectedSeverity = index == 0 ? 'שגרה' : 'דחוף';
                            if (index == 0) {
                              _addToMatabQueue = false;
                            }
                          });
                        },
                      ),
                      if (_selectedOutcome != 'COMPLETED') ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: _addToMatabQueue
                                ? AppTheme.primaryGreen.withValues(alpha: 0.14)
                                : AppTheme.backgroundPrimary,
                            borderRadius: AppTheme.radiusMd,
                            border: Border.all(
                              color: _addToMatabQueue ? AppTheme.primaryGreen : AppTheme.borderSubtle,
                            ),
                          ),
                          child: SwitchListTile(
                            dense: true,
                            activeTrackColor: AppTheme.primaryGreen,
                            secondary: Icon(
                              LucideIcons.stethoscope,
                              color: _addToMatabQueue ? AppTheme.primaryGreen : AppTheme.textSecondary,
                              size: 20,
                            ),
                            title: Text(
                              'שבץ למסדר מט"ב (לבדיקת רופא / פראמדיק היום)',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              'החייל יופיע ברשימת החיילים הממתינים לבדיקת מט"ב',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                            ),
                            value: _addToMatabQueue,
                            onChanged: (val) {
                              setState(() {
                                _addToMatabQueue = val;
                                if (val) {
                                  _selectedCategory = BattalionStaffService.matabCategory;
                                } else if (_selectedCategory == BattalionStaffService.matabCategory) {
                                  _selectedCategory = 'שגרת מרפאה';
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacing32),
                HopalButton(
                  label: widget.existingCase == null ? 'שמור פנייה' : 'עדכן פנייה',
                  onPressed: _handleCreate,
                  isLoading: _isSaving,
                  icon: LucideIcons.save,
                  isExpanded: true,
                ),
                const SizedBox(height: AppTheme.spacing48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
