import 'package:flutter/material.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/repositories/notes_repository.dart';
import 'package:chopel_app/core/models/note_model.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final _repository = NotesRepository();
  late TabController _tabController;
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    // Attempt cloud sync first
    await SyncEngine().fetchFromCloud('notes');
    
    final currentUser = AuthService().currentUser;
    if (currentUser != null && currentUser.unitId != null) {
      final notes = await _repository.getNotesByUnit(currentUser.unitId!, currentUser.id);
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showAddNoteDialog() {
    final textController = TextEditingController();
    bool isPrivate = _tabController.index == 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'הוספת הערה חדשה',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'מה תרצה לכתוב?',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Switch(
                        value: isPrivate,
                        onChanged: (val) {
                          setModalState(() {
                            isPrivate = val;
                          });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isPrivate ? 'פתק אישי (רק אני רואה)' : 'לוח הודעות (כל הפלוגה)',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (textController.text.trim().isEmpty) return;
                        
                        final currentUser = AuthService().currentUser;
                        if (currentUser == null || currentUser.unitId == null) return;

                        final note = Note(
                          id: const Uuid().v4(),
                          unitId: currentUser.unitId!,
                          userId: currentUser.id,
                          content: textController.text.trim(),
                          isPrivate: isPrivate,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        await _repository.addNote(note);
                        if (mounted) {
                          setState(() {
                            _notes.insert(0, note);
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'שמור הערה',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final privateNotes = _notes.where((n) => n.isPrivate).toList();
    final sharedNotes = _notes.where((n) => !n.isPrivate).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        title: const Text('יומן חופ"ל'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'פתקים אישיים', icon: Icon(Icons.lock_outline)),
            Tab(text: 'לוח הודעות פלוגתי', icon: Icon(Icons.group_outlined)),
          ],
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotesList(privateNotes, 'אין לך פתקים אישיים כרגע.\nלחץ על כפתור הפלוס כדי להוסיף תזכורת או הערה לעצמך.'),
                _buildNotesList(sharedNotes, 'לוח ההודעות ריק.\nכאן תוכלו לכתוב הודעות חפיפה, נהלים, או עדכונים לכל חובשי הפלוגה.'),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: Builder(
          builder: (context) {
            final isCompanyMedic = AuthService().currentUser?.role == 'COMPANY_MEDIC';
            final isSharedTab = _tabController.index == 1;
            
            if (isSharedTab && !isCompanyMedic) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton.extended(
              onPressed: _showAddNoteDialog,
              backgroundColor: AppTheme.primaryGreen,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'הערה חדשה',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes, String emptyMessage) {
    if (notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 120),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          color: AppTheme.backgroundSecondary,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(note.createdAt),
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    if (note.userId == AuthService().currentUser?.id || AuthService().currentUser?.role == 'COMPANY_MEDIC')
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteNoteConfirm(note.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteNoteConfirm(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('מחיקת הערה', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('האם אתה בטוח שברצונך למחוק הערה זו?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repository.deleteNote(id);
              _loadNotes();
            },
            child: const Text('מחק', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
