import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/models/note_model.dart';
import 'package:chopel_app/core/repositories/notes_repository.dart';
import 'package:chopel_app/core/utils/app_error_helper.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_bottom_sheet.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_card.dart';
import 'package:chopel_app/theme/components/hopal_empty_state.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final _repository = NotesRepository();
  late final TabController _tabController;
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() => _isLoading = true);
    }

    final currentUser = AuthService().currentUser;
    if (currentUser != null && currentUser.unitId != null) {
      final result = await _repository.fetchNotes(currentUser.unitId!, currentUser.id);
      if (mounted) {
        setState(() {
          _notes = result.notes;
          _isFromCache = result.isFromCache;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncLocalCache() async {
    final currentUser = AuthService().currentUser;
    if (currentUser != null && currentUser.unitId != null) {
      await _repository.saveCachedNotes(currentUser.unitId!, currentUser.id, _notes);
    }
  }

  void _showNoteEditorSheet({Note? existingNote}) {
    final isEditing = existingNote != null;
    final textController = TextEditingController(text: existingNote?.content ?? '');
    final isCompanyMedic = AuthService().isCompanyMedic;
    bool isPrivate = existingNote?.isPrivate ?? (isCompanyMedic ? _tabController.index == 0 : true);
    bool isSaving = false;

    HopalBottomSheet.show(
      context: context,
      title: isEditing ? 'עריכת הערה' : 'הוספת הערה חדשה',
      child: StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HopalTextField(
                controller: textController,
                hint: isPrivate
                    ? 'כתוב תזכורת, מעקב אישי או נקודה להמשך...'
                    : 'כתוב הודעת חפיפה, הנחיה או עדכון לכל חובשי הפלוגה...',
                maxLines: 5,
              ),
              if (isCompanyMedic) ...[
                const SizedBox(height: AppTheme.spacing16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSecondary,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPrivate ? LucideIcons.lock : LucideIcons.users,
                        color: AppTheme.primaryGreen,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          isPrivate ? 'פתק אישי (גלוי רק לי)' : 'לוח הודעות פלוגתי (גלוי לכל החובשים)',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        ),
                      ),
                      Switch(
                        value: isPrivate,
                        onChanged: isSaving
                            ? null
                            : (val) => setModalState(() => isPrivate = val),
                        activeTrackColor: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing24),
              HopalButton(
                label: isEditing ? 'שמור שינויים' : 'שמור הערה',
                icon: LucideIcons.check,
                isLoading: isSaving,
                isExpanded: true,
                onPressed: () async {
                  final content = textController.text.trim();
                  if (content.isEmpty) {
                    HopalFeedback.showError(this.context, 'נא להזין תוכן להערה');
                    return;
                  }

                  final currentUser = AuthService().currentUser;
                  if (currentUser == null || currentUser.unitId == null) return;

                  setModalState(() => isSaving = true);

                  try {
                    if (isEditing) {
                      final updated = existingNote.copyWith(
                        content: content,
                        isPrivate: isPrivate,
                        updatedAt: DateTime.now(),
                      );
                      await _repository.updateNote(updated);
                      if (mounted) {
                        setState(() {
                          final idx = _notes.indexWhere((n) => n.id == updated.id);
                          if (idx != -1) {
                            _notes[idx] = updated;
                          }
                          _isFromCache = false;
                        });
                        await _syncLocalCache();
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) {
                          HopalFeedback.showSuccess(this.context, 'ההערה עודכנה בהצלחה');
                        }
                      }
                    } else {
                      final now = DateTime.now();
                      final note = Note(
                        id: const Uuid().v4(),
                        unitId: currentUser.unitId!,
                        userId: currentUser.id,
                        content: content,
                        isPrivate: isPrivate,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await _repository.addNote(note);
                      if (mounted) {
                        setState(() {
                          _notes.insert(0, note);
                          _isFromCache = false;
                        });
                        await _syncLocalCache();
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) {
                          HopalFeedback.showSuccess(this.context, 'ההערה נשמרה בהצלחה');
                        }
                      }
                    }
                  } catch (e) {
                    if (sheetContext.mounted) {
                      setModalState(() => isSaving = false);
                    }
                    if (mounted) {
                      HopalFeedback.showError(
                        this.context,
                        AppErrorHelper.toHebrew(
                          e,
                          fallback: 'שגיאה בשמירת ההערה. בדוק חיבור ונסה שוב.',
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteNoteConfirm(Note note) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text(
          'מחיקת הערה',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'האם למחוק את ההערה הזו? הפעולה אינה הפיכה.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _repository.deleteNote(note.id);
                if (mounted) {
                  setState(() {
                    _notes.removeWhere((n) => n.id == note.id);
                  });
                  await _syncLocalCache();
                  if (mounted) {
                    HopalFeedback.showSuccess(context, 'ההערה נמחקה');
                  }
                }
              } catch (e) {
                if (mounted) {
                  HopalFeedback.showError(
                    context,
                    AppErrorHelper.toHebrew(
                      e,
                      fallback: 'שגיאה במחיקת ההערה. בדוק חיבור ונסה שוב.',
                    ),
                  );
                }
              }
            },
            child: Text(
              'מחק',
              style: TextStyle(color: AppTheme.criticalRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final privateNotes = _notes.where((n) => n.isPrivate).toList();
    final sharedNotes = _notes.where((n) => !n.isPrivate).toList();
    final isCompanyMedic = AuthService().isCompanyMedic;
    final isSharedTab = _tabController.index == 1;
    final showFab = !isSharedTab || isCompanyMedic;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        title: Text(isCompanyMedic ? 'יומן חופ"ל' : 'יומן ופנקס חובש', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(text: 'פתקים אישיים', icon: Icon(LucideIcons.lock, size: 18)),
            Tab(text: 'לוח הודעות פלוגתי', icon: Icon(LucideIcons.users, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isFromCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              color: AppTheme.warningAmber.withValues(alpha: 0.14),
              child: Row(
                children: [
                  Icon(LucideIcons.cloudOff, color: AppTheme.warningAmber, size: 16),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      'מצב אופליין – מוצגים פתקים שמורים מהמכשיר. משוך מטה לרענון.',
                      style: TextStyle(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotesTab(
                        notes: privateNotes,
                        emptyIcon: LucideIcons.notebookPen,
                        emptyTitle: 'אין פתקים אישיים כרגע',
                        emptySubtitle: 'לחץ על "הערה חדשה" כדי להוסיף תזכורת, משימה או מעקב לעצמך.',
                      ),
                      _buildNotesTab(
                        notes: sharedNotes,
                        emptyIcon: LucideIcons.megaphone,
                        emptyTitle: 'לוח ההודעות הפלוגתי ריק',
                        emptySubtitle: 'כאן יופיעו הודעות חפיפה, נהלים ועדכונים שוטפים לחובשי הפלוגה.',
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: showFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                onPressed: () => _showNoteEditorSheet(),
                backgroundColor: AppTheme.primaryGreen,
                icon: Icon(LucideIcons.plus, color: Colors.white, size: 20),
                label: const Text(
                  'הערה חדשה',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNotesTab({
    required List<Note> notes,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      backgroundColor: AppTheme.backgroundSecondary,
      onRefresh: () => _loadNotes(showSpinner: false),
      child: notes.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
                  child: HopalEmptyState(
                    icon: emptyIcon,
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing16,
                AppTheme.spacing16,
                AppTheme.spacing16,
                160,
              ),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
              itemBuilder: (context, index) {
                final note = notes[index];
                final currentUser = AuthService().currentUser;
                final isOwner = note.userId == currentUser?.id;
                final canDelete = isOwner || AuthService().isCompanyMedic;
                final isEdited = note.updatedAt.difference(note.createdAt).inSeconds > 5;

                return HopalCard(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  onTap: isOwner ? () => _showNoteEditorSheet(existingNote: note) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.content,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      Divider(height: 1, color: AppTheme.borderSubtle),
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.clock, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatDate(note.createdAt)}${isEdited ? ' • נערך' : ''}',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOwner)
                                IconButton(
                                  tooltip: 'ערוך הערה',
                                  icon: Icon(LucideIcons.pencil, color: AppTheme.textSecondary, size: 17),
                                  onPressed: () => _showNoteEditorSheet(existingNote: note),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                ),
                              if (canDelete)
                                IconButton(
                                  tooltip: 'מחק הערה',
                                  icon: Icon(LucideIcons.trash2, color: AppTheme.criticalRed, size: 17),
                                  onPressed: () => _deleteNoteConfirm(note),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}
