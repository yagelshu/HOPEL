import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:chopel_app/features/equipment/providers.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/features/learning/learning_center_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
class MedicVerificationScreen extends ConsumerWidget {
  const MedicVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const HopalEmptyState(
              icon: LucideIcons.briefcase,
              title: 'הכל תקין',
              subtitle: 'אין ציוד רפואי הממתין לאימות באחריותך.',
            );
          }

          final pendingCount = assignments.where((a) => a['verification_status'] == 'PENDING').length;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('אימות ציוד אישי', style: TextStyle(fontWeight: FontWeight.bold)),
                floating: true,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.graduationCap),
                    tooltip: 'מרכז למידה',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningCenterScreen()));
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: HopalCard(
                    backgroundColor: pendingCount > 0 
                      ? AppTheme.warningAmber.withValues(alpha: 0.1) 
                      : AppTheme.successGreen.withValues(alpha: 0.1),
                    borderColor: pendingCount > 0 
                      ? AppTheme.warningAmber.withValues(alpha: 0.3) 
                      : AppTheme.successGreen.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(AppTheme.spacing24),
                    child: Row(
                      children: [
                        Icon(
                          pendingCount > 0 ? LucideIcons.alertTriangle : LucideIcons.checkCircle2, 
                          color: pendingCount > 0 ? AppTheme.warningAmber : AppTheme.successGreen,
                          size: 28,
                        ),
                        const SizedBox(width: AppTheme.spacing16),
                        Expanded(
                          child: Text(
                            pendingCount > 0
                                ? 'יש לאמת $pendingCount פריטי ציוד חסרים לפני תחילת כוננות.'
                                : 'כל הציוד באחריותך אומת. מוכן לפעילות.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: pendingCount > 0 ? AppTheme.warningAmber : AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = assignments[index];
                      final isPending = item['verification_status'] == 'PENDING';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                        child: HopalCard(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacing12),
                                decoration: BoxDecoration(
                                  color: isPending ? AppTheme.backgroundTertiary : AppTheme.successGreen.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPending ? LucideIcons.circleDashed : LucideIcons.checkCircle2,
                                  color: isPending ? AppTheme.textMuted : AppTheme.successGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                                    const SizedBox(height: AppTheme.spacing4),
                                    Text("תוקף: ${item['expiration_date']?.split('T')[0] ?? 'לא רלוונטי'}", style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              if (isPending)
                                SizedBox(
                                  width: 100,
                                  child: HopalButton(
                                    label: 'אימות',
                                    onPressed: () async {
                                      await Supabase.instance.client
                                          .from('equipment_assignments')
                                          .update({'verification_status': 'VERIFIED'})
                                          .eq('id', item['assignment_id']);
                                      ref.invalidate(myAssignmentsProvider);
                                    },
                                  ),
                                )
                              else
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                                  child: Text('אומת', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: assignments.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, stack) => const Center(child: Text('שגיאה בטעינת נתונים')),
      ),
    );
  }
}
