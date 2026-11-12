import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/core/services/shift_handover_service.dart';
import 'package:chopel_app/core/utils/battalion_medic_helper.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_segmented_control.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

class ShiftHandoverScreen extends ConsumerStatefulWidget {
  const ShiftHandoverScreen({super.key});

  @override
  ConsumerState<ShiftHandoverScreen> createState() => _ShiftHandoverScreenState();
}

class _ShiftHandoverScreenState extends ConsumerState<ShiftHandoverScreen> {
  HandoverWindow _selectedWindow = HandoverWindow.last24Hours;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reportEditorController = TextEditingController();
  bool _isCustomEdited = false;

  @override
  void dispose() {
    _notesController.dispose();
    _reportEditorController.dispose();
    super.dispose();
  }

  void _updateGeneratedReport() {
    if (_isCustomEdited) return;

    final cases = ref.read(medicalCasesProvider).value ?? [];
    final soldiers = ref.read(soldiersProvider).value ?? [];
    final metrics = ref.read(dashboardMetricsProvider).value;

    final standbyCount = metrics?.activeMedics.where((m) => m['standby'] == true).length;
    final totalMedics = metrics?.activeMedics.length;

    final text = ShiftHandoverService.generateReport(
      cases: cases,
      soldiers: soldiers,
      window: _selectedWindow,
      activeMedicsOnStandby: standbyCount,
      totalMedicsCount: totalMedics,
      customNotes: _notesController.text.trim(),
    );

    _reportEditorController.text = text;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes
    final casesAsync = ref.watch(medicalCasesProvider);
    final soldiersAsync = ref.watch(soldiersProvider);

    if (!_isCustomEdited && !casesAsync.isLoading && !soldiersAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCustomEdited) _updateGeneratedReport();
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('דוח חפיפת מרפאה פלוגתית', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Window selector
            Text('תקופת חפיפה:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
            const SizedBox(height: AppTheme.spacing8),
            HopalSegmentedControl(
              segments: const ['24 שעות', '48 שעות', 'שבוע'],
              selectedIndex: _selectedWindow.index,
              onValueChanged: (idx) {
                try {
                  HapticFeedback.selectionClick();
                } catch (_) {}
                setState(() {
                  _selectedWindow = HandoverWindow.values[idx];
                  _isCustomEdited = false;
                });
                _updateGeneratedReport();
              },
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Additional Notes Field
            Text('דגשים מיוחדים לחובש המחליף (אופציונלי):', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
            const SizedBox(height: AppTheme.spacing8),
            HopalTextField(
              controller: _notesController,
              hint: 'לדוגמה: לבדוק שארגז חופ"ל ננעל, להזמין משחת דרמקומבין, מחלקה 1 במארב לילה...',
              maxLines: 2,
              onChanged: (_) {
                _isCustomEdited = false;
                _updateGeneratedReport();
              },
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Preview & Edit Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('תצוגה מקדימה ועריכה:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
                if (_isCustomEdited)
                  TextButton.icon(
                    icon: Icon(LucideIcons.rotateCcw, size: 14, color: AppTheme.primaryGreen),
                    label: const Text('איפוס לנוסח מקורי', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() => _isCustomEdited = false);
                      _updateGeneratedReport();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            HopalCard(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              child: TextField(
                controller: _reportEditorController,
                maxLines: 12,
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => _isCustomEdited = true,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Actions
            HopalButton(
              label: 'שתף דוח חפיפה בוואטסאפ (לחוג"ד / חובשים)',
              icon: LucideIcons.share2,
              onPressed: () async {
                final report = _reportEditorController.text.trim();
                if (report.isEmpty) return;
                await BattalionMedicHelper.sendReportToHogad(context, report);
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
            HopalButton(
              label: 'העתק דוח ללוח',
              icon: LucideIcons.copy,
              variant: HopalButtonVariant.secondary,
              onPressed: () {
                final report = _reportEditorController.text.trim();
                if (report.isEmpty) return;
                Clipboard.setData(ClipboardData(text: report));
                HopalFeedback.showSuccess(context, 'דוח החפיפה הועתק ללוח');
              },
            ),
            const SizedBox(height: AppTheme.spacing40),
          ],
        ),
      ),
    );
  }
}

