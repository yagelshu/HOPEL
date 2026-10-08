import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/screens/main_layout_screen.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class DeploymentSummaryScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final Map<String, dynamic>? summaryData;
  final String? deploymentName;
  
  const DeploymentSummaryScreen({
    super.key, 
    this.isReadOnly = false, 
    this.summaryData,
    this.deploymentName,
  });

  @override
  ConsumerState<DeploymentSummaryScreen> createState() => _DeploymentSummaryScreenState();
}

class _DeploymentSummaryScreenState extends ConsumerState<DeploymentSummaryScreen> {
  bool _isLoading = true;
  bool _isArchiving = false;
  Map<String, dynamic> _stats = {};
  String _currentDeploymentName = '';
  String _currentDeploymentId = '';

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly && widget.summaryData != null) {
      _stats = widget.summaryData!;
      _currentDeploymentName = widget.deploymentName ?? 'תעסוקה קודמת';
      _isLoading = false;
    } else {
      _loadCurrentDeploymentData();
    }
  }

  Future<void> _loadCurrentDeploymentData() async {
    final user = AuthService().currentUser;
    if (user == null || user.unitId == null || user.activeDeploymentId == null) return;
    
    _currentDeploymentId = user.activeDeploymentId!;
    
    try {
      final sb = Supabase.instance.client;
      
      // Get deployment name
      final depRes = await sb.from('deployments').select('name').eq('id', _currentDeploymentId).single();
      _currentDeploymentName = depRes['name'];

      // Get medical cases
      final casesRes = await sb.from('medical_cases').select().eq('deployment_id', _currentDeploymentId);
      final int totalCases = casesRes.length;
      
      // Calculate categories
      Map<String, int> categories = {};
      List<Map<String, dynamic>> exceptionalCases = [];
      
      for (final c in casesRes) {
        String cat = c['category'] ?? 'שגרת מרפאה';
        categories[cat] = (categories[cat] ?? 0) + 1;
        
        String severity = c['severity'] ?? 'שגרה';
        if (severity == 'חירום' || severity == 'דחוף') {
          exceptionalCases.add(c);
        }
      }
      
      // Sort categories
      var sortedCats = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      
      // Get equipment
      final eqRes = await sb.from('equipment').select().eq('unit_id', user.unitId!);
      int missingEq = 0;
      List<String> criticalMissing = [];
      
      for (final eq in eqRes) {
        if (eq['status'] == 'MISSING' || (eq['quantity'] as int) < (eq['minimum_required'] as int)) {
          missingEq++;
          if (criticalMissing.length < 3) criticalMissing.add(eq['name']);
        }
      }
      
      setState(() {
        _stats = {
          'totalCases': totalCases,
          'categories': sortedCats.map((e) => {'name': e.key, 'count': e.value}).toList(),
          'exceptionalCases': exceptionalCases.map((e) => {'description': e['description'], 'severity': e['severity'], 'date': e['created_date']}).toList(),
          'missingEquipment': missingEq,
          'totalEquipment': eqRes.length,
          'criticalMissing': criticalMissing,
          'archivedAt': DateTime.now().toIso8601String(),
        };
        _isLoading = false;
      });
      
    } catch (e) {
      HopalFeedback.showError(context, 'שגיאה בטעינת נתוני התעסוקה');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _archiveDeployment() async {
    setState(() => _isArchiving = true);
    final user = AuthService().currentUser;
    
    try {
      final sb = Supabase.instance.client;
      
      // 1. Close all cases
      await sb.from('medical_cases')
          .update({'status': 'CLOSED'})
          .eq('deployment_id', _currentDeploymentId)
          .not('status', 'eq', 'CLOSED');
          
      // 2. Clear daily schedule
      await sb.from('daily_schedule')
          .delete()
          .eq('unit_id', user!.unitId!);
          
      // 3. Update deployment table with summary and end it
      await sb.from('deployments')
          .update({
            'is_active': false,
            'end_date': DateTime.now().toIso8601String(),
            'summary_data': _stats,
          })
          .eq('id', _currentDeploymentId);
          
      // 4. Update all users in this unit to have no active deployment
      await sb.from('users')
          .update({'active_deployment_id': null})
          .eq('unit_id', user.unitId!);
          
      AuthService().updateCurrentUserDeployment(null, null);
      
      ref.invalidate(dashboardMetricsProvider);
      
      HopalFeedback.showSuccess(context, 'התעסוקה אורכבה בהצלחה!');
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
          (route) => false,
        );
      }
      
    } catch (e) {
      setState(() => _isArchiving = false);
      HopalFeedback.showError(context, 'שגיאה בארכוב התעסוקה: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isReadOnly ? 'ארכיון: $_currentDeploymentName' : 'דו"ח חפיפה: $_currentDeploymentName', 
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowRight, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
        : SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              children: [
                _buildHeader(),
                const SizedBox(height: AppTheme.spacing32),
                
                _buildCategoriesSection(),
                const SizedBox(height: AppTheme.spacing32),
                
                _buildExceptionalCasesSection(),
                const SizedBox(height: AppTheme.spacing32),
                
                _buildLogisticsSection(),
                const SizedBox(height: AppTheme.spacing32),
                
                if (!widget.isReadOnly) ...[
                  Divider(color: AppTheme.borderSubtle),
                  const SizedBox(height: AppTheme.spacing24),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    decoration: BoxDecoration(
                      color: AppTheme.criticalRed.withOpacity(0.1),
                      borderRadius: AppTheme.radiusMd,
                      border: Border.all(color: AppTheme.criticalRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, color: AppTheme.criticalRed),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Text(
                            'פעולה זו תסגור את כל הפניות הפתוחות, תאפס את הלו"ז היומי, ותעביר את הפלוגה למצב המתנה לקראת התעסוקה הבאה.',
                            style: TextStyle(color: AppTheme.criticalRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: AppTheme.spacing24),
                  HopalButton(
                    label: 'סגור וארכב תעסוקה',
                    onPressed: _isArchiving ? null : _archiveDeployment,
                    isLoading: _isArchiving,
                    isExpanded: true,
                    variant: HopalButtonVariant.destructive,
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: AppTheme.spacing48),
                ]
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    int total = _stats['totalCases'] ?? 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.fileText, color: AppTheme.primaryGreen, size: 32),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$total פניות', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text('טופלו לאורך התעסוקה', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        )
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildCategoriesSection() {
    List<dynamic> categories = _stats['categories'] ?? [];
    int total = _stats['totalCases'] ?? 1;
    if (total == 0) total = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('פילוח תחלואה גזרתי', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: AppTheme.radiusLg,
          ),
          child: Column(
            children: categories.isEmpty 
              ? [Center(child: Text('אין נתונים להצגה', style: TextStyle(color: AppTheme.textSecondary)))]
              : categories.map((cat) {
              double percentage = (cat['count'] / total);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat['name'], style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                        Text('${(percentage * 100).toInt()}% (${cat['count']})', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: AppTheme.backgroundTertiary,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildExceptionalCasesSection() {
    List<dynamic> exceptional = _stats['exceptionalCases'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('אירועי קיצון חריגים', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.criticalRed.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text('${exceptional.length}', style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        if (exceptional.isEmpty)
          Text('לא נרשמו אירועי טראומה או חירום בתעסוקה זו.', style: TextStyle(color: AppTheme.textSecondary))
        else
          ...exceptional.map((e) {
            final dateStr = e['date'] != null ? DateFormat('dd/MM/yy').format(DateTime.parse(e['date'])) : '';
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                border: Border(right: BorderSide(color: e['severity'] == 'חירום' ? AppTheme.criticalRed : AppTheme.warningAmber, width: 4)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e['description'] ?? 'ללא תיאור', style: TextStyle(color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  Text(dateStr, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            );
          }),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildLogisticsSection() {
    int totalEq = _stats['totalEquipment'] ?? 0;
    int missingEq = _stats['missingEquipment'] ?? 0;
    List<dynamic> criticalMissing = _stats['criticalMissing'] ?? [];
    
    double readyPercent = totalEq == 0 ? 1.0 : ((totalEq - missingEq) / totalEq);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('כשירות לוגיסטית בסיום התעסוקה', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: AppTheme.radiusLg,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('מוכנות ציוד רפואי', style: TextStyle(color: AppTheme.textSecondary)),
                  Text('${(readyPercent * 100).toInt()}%', style: TextStyle(color: readyPercent > 0.8 ? AppTheme.successGreen : AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (criticalMissing.isNotEmpty) ...[
                Align(alignment: Alignment.centerRight, child: Text('חוסרים בולטים:', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: criticalMissing.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundTertiary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(item, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    );
                  }).toList(),
                )
              ] else ...[
                Text('כל הציוד תקני. אין חוסרים.', style: TextStyle(color: AppTheme.successGreen))
              ]
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}
