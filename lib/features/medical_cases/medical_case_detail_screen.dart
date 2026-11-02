import 'dart:io';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class MedicalCaseDetailScreen extends ConsumerStatefulWidget {
  final MedicalCase medicalCase;

  const MedicalCaseDetailScreen({super.key, required this.medicalCase});

  @override
  ConsumerState<MedicalCaseDetailScreen> createState() => _MedicalCaseDetailScreenState();
}

class _MedicalCaseDetailScreenState extends ConsumerState<MedicalCaseDetailScreen> {
  late String _currentStatus;
  late String _currentDescription;
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
    _loadSoldierDetails();
  }
  
  Future<void> _loadSoldierDetails() async {
    try {
      final sb = Supabase.instance.client;
      final soldierRes = await sb
          .from('soldiers')
          .select('*, unit:units(name)')
          .eq('id', widget.medicalCase.soldierId)
          .maybeSingle();
          
      if (soldierRes != null) {
        final unitName = (soldierRes['unit'] as Map<String, dynamic>?)?['name'] ?? 'יחידה לא ידועה';
        final soldier = Soldier.fromMap(soldierRes);
        
        if (mounted) {
          setState(() {
            _soldier = soldier;
            _soldierName = soldier.name;
            _soldierContext = soldier.personalNumber != null
                ? '$unitName • מ.א ${soldier.personalNumber}'
                : unitName;
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

    await Supabase.instance.client
        .from('medical_cases')
        .update(updatedCase)
        .eq('id', widget.medicalCase.id);
    
    if (!mounted) return;

    setState(() {
      _currentStatus = newStatus;
      _isUpdating = false;
    });
  }

  Future<void> _shareWithDoctor() async {
    final soldierLabel = _soldier != null
        ? '${_soldier!.name}${_soldier!.personalNumber != null ? ' (מ.א ${_soldier!.personalNumber})' : ''}${_soldier!.platoon != null ? ' | מחלקה ${_soldier!.platoon}' : ''}'
        : _soldierName;

    final category = widget.medicalCase.category ?? 'שגרת מרפאה';
    final severity = widget.medicalCase.severity ?? 'שגרה';
    final statusHeb = _currentStatus == 'COMPLETED' ? 'הושלם' : 'בטיפול / מעקב';

    final buffer = StringBuffer();
    buffer.writeln('📋 *פנייה רפואית - חופ"ל*');
    buffer.writeln('👤 *חייל:* $soldierLabel');
    if (_soldier != null && _soldier!.hasAllergies) {
      buffer.writeln('🚨 *רגישות ידועה:* ${_soldier!.allergies}');
    }
    buffer.writeln('🏷️ *קטגוריה:* $category | *דחיפות:* $severity');
    buffer.writeln('🩺 *תלונה וסיכום:*');
    buffer.writeln(_currentDescription);
    buffer.writeln('📌 *סטטוס:* $statusHeb');
    buffer.writeln('\nאשמח להנחיות רופא.');

    final message = buffer.toString();
    if (widget.medicalCase.imagePath != null && widget.medicalCase.imagePath!.isNotEmpty) {
      await Share.shareXFiles([XFile(widget.medicalCase.imagePath!)], text: message);
    } else {
      await Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isCompanyMedic = user?.role == 'COMPANY_MEDIC';

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
              IconButton(
                icon: Icon(LucideIcons.trash2, color: AppTheme.criticalRed),
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
                      await Supabase.instance.client
                          .from('medical_cases')
                          .delete()
                          .eq('id', widget.medicalCase.id);
                      
                      if (context.mounted) {
                        HopalFeedback.showSuccess(context, 'התיק נמחק בהצלחה');
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        HopalFeedback.showError(context, 'שגיאה במחיקת התיק');
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'soldier_name_${widget.medicalCase.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(_soldierName, style: Theme.of(context).textTheme.headlineMedium),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text('תיק רפואי', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(_soldierContext, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        ],
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

                // Inline Status Update (Pills)
                if (isCompanyMedic) ...[
                  Text('החלטת חופ"ל:', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppTheme.spacing16),
                  Wrap(
                    spacing: AppTheme.spacing8,
                    runSpacing: AppTheme.spacing8,
                    children: [
                      _buildStatusPill('טיפול הושלם', 'COMPLETED', AppTheme.successGreen),
                      _buildStatusPill('נדרש המשך טיפול', 'REQUIRES_ATTENTION', AppTheme.warningAmber),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing48),
                ],
                
                // Image Viewer (If exists)
                if (widget.medicalCase.imagePath != null && widget.medicalCase.imagePath!.isNotEmpty) ...[
                  Text('צילום מצורף:', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppTheme.spacing16),
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.radiusLg,
                      border: Border.all(color: AppTheme.borderSubtle),
                      image: DecorationImage(
                        image: FileImage(File(widget.medicalCase.imagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing48),
                ],
                
                // Timeline (Visual Centerpiece)
                Text('רצף טיפולי (Timeline)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.spacing24),
                HopalCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24, vertical: AppTheme.spacing32),
                  child: HopalTimeline(
                    events: [
                      HopalTimelineEvent(
                        title: 'פניה נפתחה',
                        time: DateFormatter.formatRelative(widget.medicalCase.createdDate),
                        actor: 'מערכת',
                        icon: LucideIcons.filePlus2,
                        isLast: _currentStatus != 'COMPLETED',
                      ),
                      if (_currentStatus == 'COMPLETED')
                        HopalTimelineEvent(
                          title: 'התיק נסגר רפואית',
                          time: DateFormatter.formatRelative(widget.medicalCase.closedDate ?? DateTime.now().toIso8601String()),
                          actor: 'רופא / חופ"ל',
                          icon: LucideIcons.checkCircle2,
                          iconColor: AppTheme.successGreen,
                          isLast: true,
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacing64),
              ]),
            ),
          ),
        ],
      ),
    );
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
