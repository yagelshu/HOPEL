import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class LearningContentViewerScreen extends StatefulWidget {
  final String title;
  final String type; // 'VIDEO' or 'PDF'
  final String url;

  const LearningContentViewerScreen({
    super.key,
    required this.title,
    required this.type,
    required this.url,
  });

  @override
  State<LearningContentViewerScreen> createState() => _LearningContentViewerScreenState();
}

class _LearningContentViewerScreenState extends State<LearningContentViewerScreen> {
  Future<void> _openExternal() async {
    final trimmed = widget.url.trim();
    if (trimmed.isEmpty) {
      if (mounted) HopalFeedback.showError(context, 'קישור לתוכן זה אינו זמין כרגע.');
      return;
    }
    try {
      final uri = Uri.parse(trimmed);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        HopalFeedback.showError(context, 'לא ניתן לפתוח את הקישור במכשיר זה.');
      }
    } catch (_) {
      if (mounted) {
        HopalFeedback.showError(context, 'הקישור אינו תקין או שאינו זמין כרגע.');
      }
    }
  }

  Widget _buildVideoLauncher() {
    final hasRemoteUrl = widget.url.trim().startsWith('http');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HopalCard(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.video, size: 36, color: AppTheme.warningAmber),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  hasRemoteUrl
                      ? 'סרטון ההדרכה זמין לצפייה ישירה בנגן החיצוני או בדפדפן המכשיר.'
                      : 'קובץ הסרטון המקומי אינו משובץ לצפייה באפליקציה בגרסה זו.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: AppTheme.spacing24),
                if (hasRemoteUrl)
                  HopalButton(
                    label: 'פתח סרטון לצפייה',
                    icon: LucideIcons.externalLink,
                    onPressed: _openExternal,
                    isExpanded: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentViewer() {
    final isPptx = widget.url.toLowerCase().endsWith('.pptx');
    final isRemote = widget.url.trim().startsWith('http');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
          color: AppTheme.backgroundSecondary,
          child: Row(
            children: [
              Icon(isPptx ? LucideIcons.presentation : LucideIcons.fileText, color: AppTheme.textPrimary),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRemote)
                IconButton(
                  icon: Icon(LucideIcons.externalLink, color: AppTheme.primaryGreen, size: 20),
                  tooltip: 'פתח בחלון חיצוני',
                  onPressed: _openExternal,
                ),
            ],
          ),
        ),
        Expanded(
          child: isPptx
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileArchive, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: AppTheme.spacing16),
                        Text(
                          'קובץ מצגת זמין לפתיחה והורדה',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'לחץ כדי להוריד ולפתוח את המצגת במכשיר',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: AppTheme.spacing24),
                        FilledButton.icon(
                          onPressed: _openExternal,
                          icon: const Icon(LucideIcons.download),
                          label: const Text('הורד מצגת', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: AppTheme.onPrimaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : isRemote
                  ? SfPdfViewer.network(
                      widget.url,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                    )
                  : SfPdfViewer.asset(
                      widget.url,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8, vertical: AppTheme.spacing12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.type == 'VIDEO' ? 'סרטון הדרכה' : 'מסמך מקצועי',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: widget.type == 'VIDEO' ? _buildVideoLauncher() : _buildContentViewer(),
            ),
          ],
        ),
      ),
    );
  }
}
