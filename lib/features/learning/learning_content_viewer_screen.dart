import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';


class LearningContentViewerScreen extends StatefulWidget {
  final String title;
  final String type; // 'VIDEO' or 'PDF'
  final String url; // path to local asset

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate network loading for realistic feel
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Widget _buildVideoPlayerMock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(LucideIcons.playCircle, size: 64, color: Colors.white),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.pause, color: Colors.white, size: 20),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Align(
                              alignment: Alignment.centerRight, // RTL
                              child: Container(
                                width: 120, // Simulated progress
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('01:24 / 05:30', style: TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 16),
                        const Icon(LucideIcons.maximize, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: AppTheme.spacing8),
              Text('סרטון הדרכה מקצועי מבית קצין רפואה ראשי. יש לצפות בסרטון זה כחלק משמירה על כשירות חופ"ל רבעונית.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, height: 1.5)),
              const SizedBox(height: AppTheme.spacing32),
              Row(
                children: [
                  Icon(LucideIcons.checkCircle2, color: AppTheme.successGreen, size: 20),
                  SizedBox(width: AppTheme.spacing8),
                  Text('צפייה תירשם בתיק האישי שלך', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentViewer() {
    final isPptx = widget.url.toLowerCase().endsWith('.pptx');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
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
              Icon(LucideIcons.search, color: AppTheme.textSecondary),
              const SizedBox(width: AppTheme.spacing16),
              Icon(LucideIcons.share, color: AppTheme.textSecondary),
            ],
          ),
        ),
        Expanded(
          child: isPptx 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.fileArchive, size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: AppTheme.spacing16),
                      const Text('קובץ מצגת זמין להורדה', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppTheme.spacing8),
                      Text('לחץ כדי להוריד ולפתוח את המצגת', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: AppTheme.spacing24),
                      ElevatedButton.icon(
                        onPressed: () => launchUrl(Uri.parse(widget.url)),
                        icon: const Icon(LucideIcons.download),
                        label: const Text('הורד מצגת'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : widget.url.startsWith('http')
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
                      widget.type == 'VIDEO' ? 'צפייה בסרטון' : 'מסמך מקצועי', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the leading icon button width
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : widget.type == 'VIDEO' ? _buildVideoPlayerMock() : _buildContentViewer(),
            ),
          ],
        ),
      ),
    );
  }
}
