import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chopel_app/core/services/p2p_sync_service.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

class P2pSyncScreen extends ConsumerStatefulWidget {
  const P2pSyncScreen({super.key});

  @override
  ConsumerState<P2pSyncScreen> createState() => _P2pSyncScreenState();
}

class _P2pSyncScreenState extends ConsumerState<P2pSyncScreen> {
  final TextEditingController _importController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    setState(() => _isProcessing = true);
    try {
      final cases = ref.read(medicalCasesProvider).value ?? [];
      final soldiers = ref.read(soldiersProvider).value ?? [];

      final payload = await P2pSyncService.generateExportPayload(
        cases: cases,
        soldiers: soldiers,
      );

      setState(() => _isProcessing = false);

      await Share.share(
        payload,
        subject: 'חבילת סנכרון שטח חופ"ל (P2P)',
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) HopalFeedback.showError(context, 'שגיאה בהפקת חבילת הסנכרון: $e');
    }
  }

  Future<void> _handleImport() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      HopalFeedback.showError(context, 'יש להזין או להדביק את קוד חבילת הסנכרון');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await P2pSyncService.importAndMerge(text);
      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (result.success) {
        // Refresh cases provider to reload merged cache
        ref.read(medicalCasesProvider.notifier).refresh();
        _importController.clear();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.backgroundSecondary,
            title: Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: AppTheme.successGreen),
                const SizedBox(width: 8),
                Text('סנכרון P2P הושלם', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('הנתונים מוזגו בהצלחה לזיכרון המכשיר ללא תלות ברשת:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 12),
                Text('• מקור הנתונים: ${result.sourceMedic}', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text('• פניות שעודכנו/נוספו: ${result.casesMerged}', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                if (result.casesSkipped > 0)
                  Text('• פניות שכבר היו מעודכנות: ${result.casesSkipped}', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('מצוין, סגור'),
              ),
            ],
          ),
        );
      } else {
        HopalFeedback.showError(context, result.errorMessage ?? 'שגיאה בלתי צפויה בסנכרון');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) HopalFeedback.showError(context, 'שגיאה במיזוג הנתונים: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('סנכרון שטח ללא קליטה (P2P)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            // Tactical explanation banner
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.12),
                borderRadius: AppTheme.radiusMd,
                border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.radioTower, color: AppTheme.infoBlue, size: 24),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      'כלי זה מיועד למצבי לחימה (עזה, לבנון, שטח מת) שבהם אין קליטה סלולרית, ומאפשר להעביר תיקים רפואיים בין חובשים ב-Bluetooth, Quick Share, AirDrop או קוד מקומי.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Card 1: Export
            HopalCard(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.upload, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('ייצוא נתונים מקומי לחובש עמית', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'אורז את כל הפניות הרפואיות והתיקים ששמורים בטלפון שלך לחבילה ניידת ומוצפנת לשיתוף ישיר.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  HopalButton(
                    label: 'ייצא ושתף חבילת סנכרון (P2P Export)',
                    icon: LucideIcons.share2,
                    isLoading: _isProcessing,
                    onPressed: _handleExport,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Card 2: Import
            HopalCard(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.download, color: AppTheme.infoBlue, size: 20),
                      const SizedBox(width: 8),
                      Text('ייבוא ומיזוג נתונים מחובש עמית', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'הדבק כאן את חבילת הנתונים שקיבלת מחובש אחר. המערכת תמזג אוטומטית רק עדכונים חדשים.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  HopalTextField(
                    controller: _importController,
                    hint: 'הדבק קוד סנכרון (מתחיל ב-HOPEL_P2P_V1)...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(LucideIcons.clipboard, size: 14),
                        label: const Text('הדבק מלוח ההעתקה', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            setState(() => _importController.text = data!.text!);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  HopalButton(
                    label: 'בצע מיזוג נתונים למכשיר (P2P Merge)',
                    icon: LucideIcons.gitMerge,
                    variant: HopalButtonVariant.secondary,
                    isLoading: _isProcessing,
                    onPressed: _handleImport,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing40),
          ],
        ),
      ),
    );
  }
}

