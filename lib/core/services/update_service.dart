import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UpdateService {
  static final _supabase = Supabase.instance.client;

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await _supabase
          .from('app_versions')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return;

      final latestVersionData = response.first;
      final dbBuildNumber = latestVersionData['build_number'] as int;
      final downloadUrl = latestVersionData['download_url'] as String;
      final releaseNotes = latestVersionData['release_notes'] as String?;
      final isMandatory = latestVersionData['is_mandatory'] as bool? ?? false;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (dbBuildNumber > currentBuildNumber) {
        if (!context.mounted) return;
        _showUpdateDialog(context, downloadUrl, releaseNotes, isMandatory);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, String downloadUrl, String? releaseNotes, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => PopScope(
        canPop: !isMandatory,
        child: Dialog(
          backgroundColor: AppTheme.backgroundPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.downloadCloud, size: 48, color: AppTheme.primaryGreen),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'עדכון גרסה זמין',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'קיימת גרסה חדשה ומשופרת של אפליקציית חופ״ל. ${isMandatory ? 'עדכון זה הינו חובה כדי להמשיך להשתמש באפליקציה.' : 'מומלץ לעדכן כדי ליהנות מהתכונות החדשות.'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacing16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    width: double.infinity,
                    child: Text(
                      releaseNotes,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacing24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.backgroundPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final url = Uri.parse(downloadUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('הורד עדכון עכשיו', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!isMandatory) ...[
                  const SizedBox(height: AppTheme.spacing8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('הזכר לי מאוחר יותר', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
