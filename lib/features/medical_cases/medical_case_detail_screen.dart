import 'package:chopel_app/core/utils/platform_image.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:chopel_app/core/utils/doctor_consult_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_status_badge.dart';
import 'package:chopel_app/theme/components/hopal_timeline.dart';
import 'package:chopel_app/core/utils/date_formatter.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/features/medical_cases/medical_case_create_screen.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/features/equipment/providers.dart';
import 'package:chopel_app/core/services/battalion_staff_service.dart';
import 'package:chopel_app/features/medical_cases/widgets/inventory_dispense_sheet.dart';
import 'package:chopel_app/features/medical_cases/widgets/case_follow_up_widget.dart';
import 'package:chopel_app/features/profile/soldier_medical_history_screen.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalCaseDetailScreen extends ConsumerStatefulWidget {
  final MedicalCase medicalCase;

  const MedicalCaseDetailScreen({super.key, required this.medicalCase});

  @override
  ConsumerState<MedicalCaseDetailScreen> createState() => _MedicalCaseDetailScreenState();
}

class _MedicalCaseDetailScreenState extends ConsumerState<MedicalCaseDetailScreen> {
  late String _currentStatus;
  late String _currentDescription;
  late String _currentCategory;
  bool _isUpdating = false;

  String _soldierName = 'טוען...';
  String _soldierContext = 'טוען נתונים...';
  String _soldierPhone = '';
  Soldier? _soldier;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.medicalCase.status;
    _currentDescription = widget.medicalCase.description ?? 'ללא תיאור מפורט';
    _currentCategory = widget.medicalCase.category ?? 'שגרת מרפאה';
    _loadSoldierDetails();
  }

  Future<void> _loadSoldierDetails() async {
    final unitName = AuthService().currentUser?.unitName ?? 'פלוגה';

    // 1. Instant 0ms lookup from local soldiersProvider (works 100% offline!)
    final cachedSoldiers = ref.read(soldiersProvider).value ?? const [];
    final localMatch = cachedSoldiers
        .where((s) => s.id == widget.medicalCase.soldierId)
        .firstOrNull;
    if (localMatch != null) {
      final platoonPart = (localMatch.platoon != null && localMatch.platoon!.trim().isNotEmpty)
          ? ' • ${ localMatch.platoon!.trim()}'
          : '';
      final pnPart = (localMatch.personalNumber != null && localMatch.personalNumber!.isNotEmpty)
          ? ' • מ.א ${localMatch.personalNumber}'
          : '';
      if (mounted) {
        setState(() {
          _soldier = localMatch;
          _soldierName = localMatch.name;
          _soldierContext = '$unitName$platoonPart$pnPart';
          _soldierPhone = localMatch.phoneNumber ?? '';
        });
      }
      return;
    }

    // 2. Fallback to Supabase if not yet in local provider
    try {
      final sb = Supabase.instance.client;
      final soldierRes = await sb
          .from('soldiers')
          .select('*, unit:units(name)')
          .eq('id', widget.medicalCase.soldierId)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (soldierRes != null) {
        final fetchedUnitName = (soldierRes['unit'] as Map<String, dynamic>?)?['name'] ?? unitName;
        final soldier = Soldier.fromMap(soldierRes);

        if (mounted) {
          setState(() {
            _soldier = soldier;
            _soldierName = soldier.name;
            _soldierContext = soldier.personalNumber != null
                ? '$fetchedUnitName • מ.א ${soldier.personalNumber}'
                : fetchedUnitName;
            _soldierPhone = soldier.phoneNumber ?? '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _soldierName = 'חייל #${widget.medicalCase.soldierId.substring(0, 4)}';
            _soldierContext = 'לא נמצאו נתונים';
          });
        }
      }
    } catch (e) {
      // Ignored for UI
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_currentStatus == newStatus) return;

    final updatedCase = widget.medicalCase.toMap();

    if (newStatus == 'COMPLETED') {
      final String? notes = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.backgroundSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final controller = TextEditingController();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + AppTheme.spacing24,
              left: AppTheme.spacing24,
              right: AppTheme.spacing24,
              top: AppTheme.spacing24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('סיכום טיפול', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.spacing8),
                Text('הזן הערות רופא או חופ"ל לסגירת התיק.', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: AppTheme.spacing24),
                HopalTextField(
                  controller: controller,
                  hint: 'הקלד סיכום רפואי...',
                  icon: LucideIcons.fileText,
                ),
                const SizedBox(height: AppTheme.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: HopalButton(
                        label: 'ביטול',
                        variant: HopalButtonVariant.secondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                    Expanded(
                      child: HopalButton(
                        label: 'סגור תיק',
                        icon: LucideIcons.checkCircle2,
                        onPressed: () => Navigator.pop(context, controller.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
      if (notes == null) return; // cancelled
      updatedCase['closed_date'] = DateTime.now().toIso8601String();
      if (notes.trim().isNotEmpty) {
        final newDesc = '${updatedCase['description'] ?? ''}\n\n[סיכום טיפול]: $notes'.trim();
        updatedCase['description'] = newDesc;
        setState(() {
          _currentDescription = newDesc;
        });
      }
    }

    setState(() => _isUpdating = true);
    updatedCase['status'] = newStatus;
    updatedCase['updated_date'] = DateTime.now().toIso8601String();

    await ref
        .read(medicalCasesProvider.notifier)
        .upsertCaseOptimistically(MedicalCase.fromMap(updatedCase));
    ref.invalidate(dashboardMetricsProvider);

    if (!mounted) return;

    setState(() {
      _currentStatus = newStatus;
      _isUpdating = false;
    });
  }

  Future<void> _addClinicalFollowUpEntry() async {
    final noteController = TextEditingController();
    const quickFollowUpChips = [
      'בדיקת חום חוזרת תקינה',
      'נבדק ע"י מט"ב',
      'חל שיפור בתסמינים',
      'הונחה להמשך מנוחה ושתייה',
      'ללא החמרה או דגלים אדומים',
    ];

    final addedText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom +
                MediaQuery.of(sheetCtx).padding.bottom +
                AppTheme.spacing24,
            left: AppTheme.spacing20,
            right: AppTheme.spacing20,
            top: AppTheme.spacing20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.clipboardPlus, color: AppTheme.primaryGreen, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'הוספת עדכון מעקב / הוראת מט"ב',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'העדכון יתווסף עם חותמת תאריך, שעה ושם המטפל לציר הזמן של הפנייה:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickFollowUpChips.map((chip) {
                  return ActionChip(
                    label: Text(chip, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.backgroundTertiary,
                    onPressed: () {
                      final cur = noteController.text.trim();
                      noteController.text = cur.isEmpty ? chip : '$cur, $chip';
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              HopalTextField(
                controller: noteController,
                hint: 'הקלד ממצאי מעקב, מדדים חוזרים או הוראת רופא...',
                icon: LucideIcons.fileText,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              HopalButton(
                label: 'שמור עדכון בתיק הפנייה',
                icon: LucideIcons.check,
                onPressed: () {
                  final text = noteController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(sheetCtx, text);
                },
              ),
            ],
          ),
        );
      },
    );

    if (addedText == null || addedText.isEmpty || !mounted) return;

    final now = DateTime.now();
    final timeStamp =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final medicName = AuthService().effectiveUserName;
    final entryLine = '📌 [$timeStamp • $medicName]: $addedText';
    final newDesc = '$_currentDescription\n$entryLine';

    final updatedMap = widget.medicalCase.toMap();
    updatedMap['description'] = newDesc;
    updatedMap['status'] = _currentStatus;
    updatedMap['category'] = _currentCategory;
    updatedMap['updated_date'] = now.toIso8601String();

    setState(() {
      _currentDescription = newDesc;
    });

    await ref
        .read(medicalCasesProvider.notifier)
        .upsertCaseOptimistically(MedicalCase.fromMap(updatedMap));
    ref.invalidate(dashboardMetricsProvider);

    if (mounted) {
      HopalFeedback.showSuccess(context, 'עדכון המעקב נוסף לתיק הפנייה');
    }
  }

  Future<void> _shareWithDoctor() {
    return DoctorConsultHelper.shareMedicalCase(
      context,
      medicalCase: widget.medicalCase,
      soldier: _soldier,
      fallbackSoldierName: _soldierName,
      descriptionOverride: _currentDescription,
      statusOverride: _currentStatus,
    );
  }

  Future<void> _dispenseEquipmentForCase() async {
    final allEquipment = ref.read(equipmentProvider).value ?? [];
    final picked = await InventoryDispenseHelper.showPickerSheet(
      context,
      allEquipment: allEquipment,
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    final summaryLine = InventoryDispenseHelper.formatDispensedSummary(picked);
    final newDesc = '$_currentDescription\n$summaryLine';

    final notifier = ref.read(equipmentProvider.notifier);
    for (final item in picked) {
      if (item.quantity > 0) {
        await notifier.adjustQuantity(item.equipmentId, -item.quantity);
      }
    }

    final updatedMap = widget.medicalCase.toMap();
    updatedMap['description'] = newDesc;
    updatedMap['status'] = _currentStatus;
    updatedMap['category'] = _currentCategory;
    updatedMap['updated_date'] = DateTime.now().toIso8601String();

    await ref
        .read(medicalCasesProvider.notifier)
        .upsertCaseOptimistically(MedicalCase.fromMap(updatedMap));

    if (mounted) {
      setState(() {
        _currentDescription = newDesc;
      });
      ref.invalidate(dashboardMetricsProvider);
      HopalFeedback.showSuccess(context, 'הציוד שנופק הופחת אוטומטית מהמלאי ותועד בתיק');
    }
  }

  Future<void> _toggleMatabQueue() async {
    final isCurrentlyInQueue = _currentCategory == BattalionStaffService.matabCategory;
    final nextCategory = isCurrentlyInQueue ? 'שגרת מרפאה' : BattalionStaffService.matabCategory;
    final nextStatus = (!isCurrentlyInQueue && _currentStatus == 'COMPLETED')
        ? 'REQUIRES_ATTENTION'
        : _currentStatus;

    final updatedMap = widget.medicalCase.toMap();
    updatedMap['description'] = _currentDescription;
    updatedMap['category'] = nextCategory;
    updatedMap['status'] = nextStatus;
    updatedMap['updated_date'] = DateTime.now().toIso8601String();

    await ref
        .read(medicalCasesProvider.notifier)
        .upsertCaseOptimistically(MedicalCase.fromMap(updatedMap));

    if (mounted) {
      setState(() {
        _currentCategory = nextCategory;
        _currentStatus = nextStatus;
      });
      ref.invalidate(dashboardMetricsProvider);
      HopalFeedback.showSuccess(
        context,
        !isCurrentlyInQueue
            ? 'החייל שובץ למסדר מט"ב להיום 🩺'
            : 'החייל הוסר ממסדר מט"ב',
      );
    }
  }

  void _showFullScreenPhoto(String path, {String? tag}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppTheme.spacing16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image(
                  image: resolveLocalOrWebImage(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(LucideIcons.imageOff, color: AppTheme.textMuted, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            if (tag != null && tag.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.tag, color: AppTheme.primaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          tag,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(equipmentProvider);
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService().previewAsCombatMedicNotifier,
      builder: (context, _, __) {
        final isCompanyMedic = AuthService().isCompanyMedic;

        return Scaffold(
          backgroundColor: AppTheme.backgroundPrimary,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text('תיק רפואי פעיל', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                backgroundColor: AppTheme.backgroundPrimary,
                elevation: 0,
                centerTitle: true,
                pinned: true,
                floating: true,
                leading: IconButton(
                  icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(LucideIcons.share2, color: AppTheme.primaryGreen),
                    tooltip: 'שיתוף תיק לרופא',
                    onPressed: _shareWithDoctor,
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.edit2, color: AppTheme.infoBlue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicalCaseCreateScreen(existingCase: widget.medicalCase),
                        ),
                      ).then((_) {
                        if (context.mounted) Navigator.pop(context);
                      });
                    },
                  ),
                  if (isCompanyMedic)
                    IconButton(
                      icon: Icon(LucideIcons.trash2, color: AppTheme.criticalRed),
                      tooltip: 'מחיקת תיק רפואי',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.backgroundSecondary,
                            title: Text('מחיקת תיק רפואי', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                            content: Text('האם אתה בטוח שברצונך למחוק את התיק הזה לחלוטין? פעולה זו אינה הפיכה.', style: TextStyle(color: AppTheme.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('מחק תיק', style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await ref
                                .read(medicalCasesProvider.notifier)
                                .deleteCaseOptimistically(widget.medicalCase.id);
                            ref.invalidate(dashboardMetricsProvider);

                            if (context.mounted) {
                              HopalFeedback.showSuccess(context, 'התיק נמחק בהצלחה');
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              HopalFeedback.showError(
                                context,
                                AppErrorHelper.toHebrew(e, fallback: 'שגיאה במחיקת התיק'),
                              );
                            }
                          }
                        }
                      },
                    ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _soldier != null
                                ? () {
                                    try {
                                      HapticFeedback.lightImpact();
                                    } catch (_) {}
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SoldierMedicalHistoryScreen(soldier: _soldier!),
                                      ),
                                    );
                                  }
                                : null,
                            borderRadius: AppTheme.radiusSm,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Hero(
                                      tag: 'soldier_name_${widget.medicalCase.id}',
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: Text(_soldierName, style: Theme.of(context).textTheme.headlineMedium),
                                      ),
                                    ),
                                    if (_soldier != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.folderHeart, size: 20, color: AppTheme.primaryGreen),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Row(
                                  children: [
                                    Text('תיק אישי והיסטוריה רפואית', style: TextStyle(fontSize: 13.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.chevronLeft, size: 14, color: AppTheme.primaryGreen),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Text(_soldierContext, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                        _buildOutcomeBadge(),
                      ],
                    ),

                    if (_soldier != null && _soldier!.hasAllergies) ...[
                      const SizedBox(height: AppTheme.spacing16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: AppTheme.criticalRed.withValues(alpha: 0.15),
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.alertTriangle, color: AppTheme.criticalRed, size: 20),
                            const SizedBox(width: AppTheme.spacing12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'אזהרה רפואית: אלרגיה / רגישות ידועה',
                                    style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    _soldier!.allergies!,
                                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacing32),

                    Text('תיאור תסמינים וסיכום:', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(_currentDescription, style: TextStyle(fontSize: 16, color: AppTheme.textPrimary, height: 1.5)),

                    const SizedBox(height: AppTheme.spacing24),

                    // Contact Actions
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextButton.icon(
                            onPressed: _shareWithDoctor,
                            icon: const Icon(LucideIcons.stethoscope, size: 18),
                            label: const Text('התייעצות רופא (WhatsApp)', overflow: TextOverflow.ellipsis),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        if (_soldierPhone.isNotEmpty) ...[
                          const SizedBox(width: AppTheme.spacing8),
                          IconButton(
                            tooltip: 'חיוג לחייל',
                            icon: Icon(LucideIcons.phone, color: AppTheme.primaryGreen),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse('tel:${_soldierPhone.replaceAll(RegExp(r'\D'), '')}');
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                          ),
                          IconButton(
                            tooltip: 'הודעה לחייל',
                            icon: Icon(LucideIcons.messageCircle, color: AppTheme.infoBlue),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.infoBlue.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final text = Uri.encodeComponent('היי $_soldierName, מה המצב?');
                              var formattedPhone = _soldierPhone.replaceAll(RegExp(r'\D'), '');
                              if (formattedPhone.startsWith('0')) formattedPhone = '972${formattedPhone.substring(1)}';
                              final url = Uri.parse('https://wa.me/$formattedPhone?text=$text');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppTheme.spacing40),

                    // Inline Status Update (Pills) & Quick Actions
                    Text(
                      isCompanyMedic ? 'החלטת חופ"ל ופעולות מהירות:' : 'פעולות מעקב לחובש:',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    if (isCompanyMedic) ...[
                      Wrap(
                        spacing: AppTheme.spacing8,
                        runSpacing: AppTheme.spacing8,
                        children: [
                          _buildStatusPill('טיפול הושלם', 'COMPLETED', AppTheme.successGreen),
                          _buildStatusPill('נדרש המשך טיפול', 'REQUIRES_ATTENTION', AppTheme.warningAmber),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                    ],
                    Wrap(
                      spacing: AppTheme.spacing8,
                      runSpacing: AppTheme.spacing8,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                            shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusPill),
                          ),
                          icon: const Icon(LucideIcons.clipboardPlus, size: 16),
                          label: const Text('הוסף עדכון מעקב / הוראת מט"ב', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: _addClinicalFollowUpEntry,
                        ),
                        if (isCompanyMedic)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                              shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusPill),
                            ),
                            icon: const Icon(LucideIcons.packageMinus, size: 16),
                            label: const Text('נפק תרופה / ציוד מהמלאי', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _dispenseEquipmentForCase,
                          ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _currentCategory == BattalionStaffService.matabCategory
                                ? AppTheme.infoBlue.withValues(alpha: 0.15)
                                : Colors.transparent,
                            foregroundColor: AppTheme.infoBlue,
                            side: BorderSide(
                              color: _currentCategory == BattalionStaffService.matabCategory
                                  ? AppTheme.infoBlue
                                  : AppTheme.infoBlue.withValues(alpha: 0.5),
                            ),
                            shape: const RoundedRectangleBorder(borderRadius: AppTheme.radiusPill),
                          ),
                          icon: Icon(
                            _currentCategory == BattalionStaffService.matabCategory
                                ? LucideIcons.checkCircle2
                                : LucideIcons.stethoscope,
                            size: 16,
                          ),
                          label: Text(
                            _currentCategory == BattalionStaffService.matabCategory
                                ? 'משובץ למסדר מט"ב (לחץ להסרה)'
                                : 'שבץ למסדר מט"ב היום',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _toggleMatabQueue,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing48),

                    // Image Viewer (Supports multiple photos with complaint tags)
                    if (widget.medicalCase.photos.isNotEmpty) ...[
                      Builder(builder: (context) {
                        final photos = widget.medicalCase.photos;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photos.length == 1
                                  ? 'צילום רפואי מצורף (לחץ להגדלה):'
                                  : 'צילומים רפואיים מצורפים (${photos.length}):',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            if (photos.length == 1)
                              InkWell(
                                onTap: () => _showFullScreenPhoto(photos.first.path, tag: photos.first.complaintTag),
                                borderRadius: AppTheme.radiusLg,
                                child: ClipRRect(
                                  borderRadius: AppTheme.radiusLg,
                                  child: Container(
                                    width: double.infinity,
                                    height: 250,
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundSecondary,
                                      border: Border.all(color: AppTheme.borderSubtle),
                                      borderRadius: AppTheme.radiusLg,
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image(
                                          image: resolveLocalOrWebImage(photos.first.path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(LucideIcons.imageOff, color: AppTheme.textMuted, size: 32),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'לא ניתן לטעון תמונה ישנה במכשיר זה',
                                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (photos.first.complaintTag != null && photos.first.complaintTag!.isNotEmpty)
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.75),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(LucideIcons.tag, color: AppTheme.primaryGreen, size: 13),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    photos.first.complaintTag!,
                                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 210,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photos.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, idx) {
                                    final p = photos[idx];
                                    return InkWell(
                                      onTap: () => _showFullScreenPhoto(p.path, tag: p.complaintTag),
                                      borderRadius: AppTheme.radiusMd,
                                      child: ClipRRect(
                                        borderRadius: AppTheme.radiusMd,
                                        child: Container(
                                          width: 170,
                                          decoration: BoxDecoration(
                                            color: AppTheme.backgroundSecondary,
                                            border: Border.all(color: AppTheme.borderSubtle),
                                            borderRadius: AppTheme.radiusMd,
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image(
                                                image: resolveLocalOrWebImage(p.path),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Center(
                                                  child: Icon(LucideIcons.imageOff, color: AppTheme.textMuted, size: 28),
                                                ),
                                              ),
                                              if (p.complaintTag != null && p.complaintTag!.isNotEmpty)
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  left: 8,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.78),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(LucideIcons.tag, color: AppTheme.primaryGreen, size: 12),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            p.complaintTag!,
                                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: AppTheme.spacing48),
                    ],

                    // Timeline (Visual Centerpiece)
                    Text('רצף טיפולי (Timeline)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: AppTheme.spacing24),
                    HopalCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing32),
                      child: HopalTimeline(
                        events: _buildTimelineEvents(),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing32),
                    CaseFollowUpWidget(
                      caseId: widget.medicalCase.id,
                      soldierId: widget.medicalCase.soldierId,
                      soldierName: _soldierName,
                    ),

                    const SizedBox(height: AppTheme.spacing64),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<HopalTimelineEvent> _buildTimelineEvents() {
    String creatorActor = 'חופ"ל / חובש';
    final followUps = <Map<String, String>>[];

    for (final rawLine in _currentDescription.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('🩺 תועד ע"י:')) {
        creatorActor = line.replaceFirst('🩺 תועד ע"י:', '').trim();
      } else if (line.startsWith('📌 [')) {
        final closeBracket = line.indexOf(']:');
        if (closeBracket != -1) {
          final meta = line.substring(line.indexOf('[') + 1, closeBracket);
          final content = line.substring(closeBracket + 2).trim();
          final parts = meta.split('•');
          final timeStr = parts.first.trim();
          final actorStr = parts.length > 1 ? parts.last.trim() : 'חופ"ל';
          followUps.add({
            'title': content,
            'time': timeStr,
            'actor': actorStr,
          });
        }
      }
    }

    final events = <HopalTimelineEvent>[
      HopalTimelineEvent(
        title: 'פניה נפתחה',
        time: DateFormatter.formatRelative(widget.medicalCase.createdDate),
        actor: creatorActor,
        icon: LucideIcons.filePlus2,
        isLast: followUps.isEmpty && _currentStatus != 'COMPLETED',
      ),
    ];

    for (int i = 0; i < followUps.length; i++) {
      final f = followUps[i];
      final isLastEvent = (i == followUps.length - 1) && _currentStatus != 'COMPLETED';
      events.add(
        HopalTimelineEvent(
          title: f['title'] ?? 'עדכון מעקב',
          time: f['time'] ?? '',
          actor: f['actor'] ?? 'חופ"ל',
          icon: LucideIcons.clipboardCheck,
          iconColor: AppTheme.infoBlue,
          isLast: isLastEvent,
        ),
      );
    }

    if (_currentStatus == 'COMPLETED') {
      events.add(
        HopalTimelineEvent(
          title: 'התיק נסגר רפואית',
          time: DateFormatter.formatRelative(
            widget.medicalCase.closedDate ?? DateTime.now().toIso8601String(),
          ),
          actor: 'רופא / חופ"ל',
          icon: LucideIcons.checkCircle2,
          iconColor: AppTheme.successGreen,
          isLast: true,
        ),
      );
    }

    return events;
  }

  Widget _buildOutcomeBadge() {
    if (_currentStatus == 'REQUIRES_ATTENTION') {
      return const HopalStatusBadge(label: 'בטיפול / מעקב', icon: LucideIcons.stethoscope, variant: HopalStatusBadgeVariant.warning);
    }
    return const HopalStatusBadge(label: 'טופל', icon: LucideIcons.checkCircle2, variant: HopalStatusBadgeVariant.neutral);
  }

  Widget _buildStatusPill(String label, String value, Color color) {
    final isSelected = _currentStatus == value;

    return GestureDetector(
      onTap: _isUpdating ? null : () => _updateStatus(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.backgroundSecondary,
          borderRadius: AppTheme.radiusPill,
          border: Border.all(color: isSelected ? color : AppTheme.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(LucideIcons.checkCircle2, size: 16, color: color),
              const SizedBox(width: AppTheme.spacing8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
