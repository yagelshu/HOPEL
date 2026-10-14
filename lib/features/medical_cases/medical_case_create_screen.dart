import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/components/hopal_button.dart';
import 'package:chopel_app/theme/components/hopal_text_field.dart';
import 'package:chopel_app/theme/components/hopal_form_section.dart';
import 'package:chopel_app/theme/components/hopal_feedback.dart';
import 'package:chopel_app/theme/components/hopal_segmented_control.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/features/medical_cases/providers.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/core/ai/medical_copilot_service.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/database/draft_service.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalCaseCreateScreen extends ConsumerStatefulWidget {
  final MedicalCase? existingCase;

  const MedicalCaseCreateScreen({super.key, this.existingCase});

  @override
  ConsumerState<MedicalCaseCreateScreen> createState() => _MedicalCaseCreateScreenState();
}

class _MedicalCaseCreateScreenState extends ConsumerState<MedicalCaseCreateScreen> {
  String? _selectedSoldierId;
  final _descController = TextEditingController();
  
  String _selectedOutcome = 'COMPLETED';
  String _selectedCategory = 'שגרת מרפאה';
  String _selectedSeverity = 'שגרה';

  bool _isSaving = false;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingCase != null) {
      _selectedSoldierId = widget.existingCase!.soldierId;
      _descController.text = widget.existingCase!.description ?? '';
      _selectedOutcome = widget.existingCase!.status;
      _selectedCategory = widget.existingCase!.category ?? 'שגרת מרפאה';
      _selectedSeverity = widget.existingCase!.severity ?? 'שגרה';
      _imagePath = widget.existingCase!.imagePath;
    } else {
      _loadDraft();
    }
    
    _descController.addListener(_saveDraft);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('medical_case_draft');
    if (draft != null && draft.isNotEmpty && mounted) {
      setState(() => _descController.text = draft);
    }
  }

  Future<void> _saveDraft() async {
    if (widget.existingCase == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('medical_case_draft', _descController.text);
    }
  }

  @override
  void dispose() {
    _descController.removeListener(_saveDraft);
    _descController.dispose();
    super.dispose();
  }

  final List<String> _quickTags = [
    'שפשפות', 'חום/צינון', 'כאבי גרון', 'כאבי בטן/שלשולים', 'כאב ראש', 'כאבי גב/ברכיים', 'נקע/חבלה', 'פטרת/פריחה', 'טראומה', 'בקשת תור לרופא', 'הוצאת גימלים'
  ];

  void _addTag(String tag) {
    final current = _descController.text;
    if (current.isEmpty) {
      _descController.text = tag;
    } else {
      _descController.text = '$current, $tag';
    }
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.backgroundSecondary,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(LucideIcons.camera, color: AppTheme.textPrimary),
                title: Text('צלם תמונה', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(LucideIcons.image, color: AppTheme.textPrimary),
                title: Text('בחר מהגלריה', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      HopalFeedback.showError(context, 'שגיאה בטעינת התמונה');
    }
  }

  void _showAddSoldierDialog() {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text('הוספת חייל חדש', style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HopalTextField(
                controller: nameController,
                hint: 'שם מלא (לדוגמה: ישראל ישראלי)',
                icon: LucideIcons.user,
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: idController,
                hint: 'מספר אישי',
                icon: LucideIcons.hash,
              ),
              const SizedBox(height: AppTheme.spacing16),
              HopalTextField(
                controller: phoneController,
                hint: 'טלפון (אופציונלי)',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ביטול', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              if (nameController.text.isEmpty || idController.text.isEmpty) {
                HopalFeedback.showError(context, 'נא למלא את כל השדות');
                return;
              }
              
              final user = AuthService().currentUser;
              final soldierId = const Uuid().v4();
              final personalNum = idController.text.trim();
              
              final payload = {
                'id': soldierId,
                'name': nameController.text.trim(),
                'personal_number': personalNum,
                'unit_id': user?.unitId,
                'phone_number': phoneController.text.trim(),
              };

              try {
                await Supabase.instance.client.from('soldiers').insert(payload);
                
                if (!context.mounted) return;
                ref.invalidate(soldiersProvider);
                Navigator.pop(context);
                setState(() {
                  _selectedSoldierId = soldierId;
                });
                HopalFeedback.showSuccess(context, 'חייל נוסף בהצלחה');
              } catch (e) {
                if (context.mounted) {
                  HopalFeedback.showError(context, 'שגיאה בהוספת חייל: $e');
                }
              }
            },
            child: Text('הוסף חייל', style: TextStyle(color: AppTheme.backgroundPrimary)),
          ),
        ],
      ),
    );
  }

  void _openSoldierSearchSheet(List<Soldier> soldiers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';
        String selectedPlatoon = 'הכל';

        final platoons = <String>['הכל'];
        for (final s in soldiers) {
          if (s.platoon != null && s.platoon!.trim().isNotEmpty && !platoons.contains(s.platoon!.trim())) {
            platoons.add(s.platoon!.trim());
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = searchQuery.trim().toLowerCase();
            final filtered = soldiers.where((s) {
              final matchesQuery = q.isEmpty ||
                  s.name.toLowerCase().contains(q) ||
                  (s.personalNumber != null && s.personalNumber!.contains(q)) ||
                  (s.phoneNumber != null && s.phoneNumber!.contains(q)) ||
                  (s.platoon != null && s.platoon!.toLowerCase().contains(q));
              final matchesPlatoon = selectedPlatoon == 'הכל' || s.platoon?.trim() == selectedPlatoon;
              return matchesQuery && matchesPlatoon;
            }).toList();
            filtered.sort((a, b) => a.name.compareTo(b.name));

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                top: AppTheme.spacing16,
                left: AppTheme.spacing16,
                right: AppTheme.spacing16,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('בחירת חייל מהפלוגה',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      TextButton.icon(
                        icon: const Icon(LucideIcons.userPlus, size: 16),
                        label: const Text('חייל חדש'),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddSoldierDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: TextStyle(color: AppTheme.textPrimary),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'הקלד שם, מספר אישי או מחלקה...',
                      prefixIcon: Icon(LucideIcons.search, color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.backgroundTertiary,
                      border: OutlineInputBorder(borderRadius: AppTheme.radiusMd, borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (platoons.length > 2) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: platoons.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final p = platoons[i];
                          final isSel = selectedPlatoon == p;
                          return ChoiceChip(
                            label: Text(p),
                            selected: isSel,
                            onSelected: (_) => setModalState(() => selectedPlatoon = p),
                            selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            backgroundColor: AppTheme.backgroundTertiary,
                            labelStyle: TextStyle(
                              color: isSel ? AppTheme.primaryGreen : AppTheme.textSecondary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.userX, size: 40, color: AppTheme.textSecondary),
                                const SizedBox(height: 8),
                                Text('לא נמצא חייל תואם', style: TextStyle(color: AppTheme.textSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showAddSoldierDialog();
                                  },
                                  icon: const Icon(LucideIcons.userPlus, size: 16, color: Colors.white),
                                  label: const Text('הוסף חייל חדש עכשיו', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final s = filtered[index];
                              final hasPn = s.personalNumber != null && s.personalNumber!.isNotEmpty;
                              final hasPlatoon = s.platoon != null && s.platoon!.isNotEmpty;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                  child: Icon(LucideIcons.user, color: AppTheme.primaryGreen),
                                ),
                                title: Text(s.name,
                                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  [
                                    if (hasPn) 'מ.א: ${s.personalNumber}',
                                    if (hasPlatoon) 'מחלקה ${s.platoon}',
                                    if (s.phoneNumber != null) s.phoneNumber!,
                                  ].join(' • '),
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                onTap: () {
                                  setState(() => _selectedSoldierId = s.id);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runCopilot() async {
    final complaint = _descController.text.trim();
    if (complaint.isEmpty) {
      HopalFeedback.showError(context, 'נא להזין או לבחור תלונות תחילה');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: MedicalCopilotService().analyzeSymptoms(complaint),
          builder: (context, snapshot) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.sparkles, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('AI Copilot - המלצות רפואיות', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ),
                        IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                    else if (snapshot.hasError)
                      Text('שגיאה בגישה ל-AI: ${snapshot.error}', style: TextStyle(color: AppTheme.warningAmber))
                    else if (snapshot.hasData) ...[
                      Text('אבחנה משוערת:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      Text(snapshot.data!['diagnosis'], style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                      const SizedBox(height: AppTheme.spacing16),
                      Text('המלצת טיפול:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      Text(snapshot.data!['treatment'], style: TextStyle(color: AppTheme.textPrimary)),
                      const SizedBox(height: AppTheme.spacing16),
                      if (snapshot.data!['redFlags'].isNotEmpty) ...[
                        Text('דגלים אדומים (סכנה):', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningAmber)),
                        ...List.generate(snapshot.data!['redFlags'].length, (index) => Text('• ${snapshot.data!['redFlags'][index]}', style: TextStyle(color: AppTheme.textPrimary))),
                        const SizedBox(height: AppTheme.spacing16),
                      ],
                      if (snapshot.data!['medications'].isNotEmpty) ...[
                        Text('תרופות מארגז חופ"ל:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.infoBlue)),
                        ...List.generate(snapshot.data!['medications'].length, (index) => Text('• ${snapshot.data!['medications'][index]}', style: TextStyle(color: AppTheme.textPrimary))),
                      ],
                      const SizedBox(height: AppTheme.spacing24),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleCreate() async {
    if (_selectedSoldierId == null) {
      HopalFeedback.showError(context, 'יש לבחור חייל');
      return;
    }

    if (_descController.text.trim().isEmpty) {
      HopalFeedback.showError(context, 'יש להזין תיאור / אבחנה רפואית');
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'soldier_id': _selectedSoldierId,
      'status': _selectedOutcome,
      'description': _descController.text.trim(),
      'category': _selectedCategory,
      'severity': _selectedSeverity,
      'updated_date': DateTime.now().toIso8601String(),
      'image_path': _imagePath,
    };

    try {
      if (widget.existingCase == null) {
        payload['id'] = const Uuid().v4();
        payload['created_date'] = DateTime.now().toIso8601String();
        payload['deployment_id'] = AuthService().currentUser?.activeDeploymentId;
        await Supabase.instance.client.from('medical_cases').insert(payload);
      } else {
        await Supabase.instance.client.from('medical_cases').update(payload).eq('id', widget.existingCase!.id);
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup') || e.toString().contains('ClientException')) {
        if (widget.existingCase != null) {
          if (mounted) HopalFeedback.showError(context, 'עריכת תיק רפואי דורשת חיבור זמין לאינטרנט');
          setState(() => _isSaving = false);
          return;
        }
        await DraftService.saveDraft(payload);
        if (mounted) {
          HopalFeedback.showSuccess(context, 'אין קליטה - התיק נשמר בטיוטות ויסונכרן בהמשך');
          Navigator.pop(context);
        }
        return;
      }
      if (mounted) HopalFeedback.showError(context, 'שגיאה בשמירת התיק: $e');
      setState(() => _isSaving = false);
      return;
    }

    if (!mounted) return;
    
    if (widget.existingCase == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('medical_case_draft');
    }
    
    // Refresh the list providers
    ref.read(medicalCasesProvider.notifier).refresh();
    ref.invalidate(dashboardMetricsProvider);
    
    HopalFeedback.showSuccess(context, widget.existingCase == null ? 'הפנייה הרפואית נפתחה בהצלחה' : 'הפנייה הרפואית עודכנה בהצלחה');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final soldiersAsync = ref.watch(soldiersProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(widget.existingCase == null ? 'פנייה חדשה' : 'עריכת פנייה', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
            backgroundColor: AppTheme.backgroundPrimary,
            elevation: 0,
            centerTitle: true,
            pinned: true,
            floating: true,
            leading: IconButton(
              icon: Icon(LucideIcons.x, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HopalFormSection(
                  title: 'חייל מטופל',
                  children: [
                    soldiersAsync.when(
                      data: (soldiers) {
                        final soldier = soldiers.where((s) => s.id == _selectedSoldierId).firstOrNull;

                        if (soldier != null) {
                          final hasPhone = soldier.phoneNumber != null && soldier.phoneNumber!.trim().isNotEmpty;
                          return Container(
                            padding: const EdgeInsets.all(AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: AppTheme.radiusMd,
                              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                      child: Icon(LucideIcons.userCheck, color: AppTheme.primaryGreen),
                                    ),
                                    const SizedBox(width: AppTheme.spacing12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(soldier.name,
                                              style: TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              if (soldier.personalNumber != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.backgroundTertiary,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('מ.א: ${soldier.personalNumber}',
                                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                                ),
                                              if (soldier.platoon != null && soldier.platoon!.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('מחלקה ${soldier.platoon}',
                                                      style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(LucideIcons.refreshCw, color: AppTheme.textSecondary, size: 18),
                                      tooltip: 'החלף חייל',
                                      onPressed: () => _openSoldierSearchSheet(soldiers),
                                    ),
                                    IconButton(
                                      icon: Icon(LucideIcons.x, color: AppTheme.criticalRed, size: 18),
                                      tooltip: 'נקה בחירה',
                                      onPressed: () => setState(() => _selectedSoldierId = null),
                                    ),
                                  ],
                                ),
                                if (hasPhone) ...[
                                  const SizedBox(height: 12),
                                  Divider(color: AppTheme.borderSubtle, height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.phone, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(soldier.phoneNumber!,
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                      const Spacer(),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        icon: Icon(LucideIcons.phoneCall, size: 14, color: AppTheme.primaryGreen),
                                        label: Text('חייג', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                                        onPressed: () async {
                                          final uri = Uri.parse('tel:${soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '')}');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                                        },
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        icon: Icon(LucideIcons.messageCircle, size: 14, color: AppTheme.successGreen),
                                        label: Text('WhatsApp', style: TextStyle(color: AppTheme.successGreen, fontSize: 12)),
                                        onPressed: () async {
                                          var phone = soldier.phoneNumber!.replaceAll(RegExp(r'\D'), '');
                                          if (phone.startsWith('0')) phone = '972${phone.substring(1)}';
                                          final uri = Uri.parse('https://wa.me/$phone');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          onTap: () => _openSoldierSearchSheet(soldiers),
                          borderRadius: AppTheme.radiusMd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: AppTheme.radiusMd,
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  child: Icon(LucideIcons.userSearch, color: AppTheme.primaryGreen),
                                ),
                                const SizedBox(width: AppTheme.spacing16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('בחר חייל מהפלוגה...',
                                          style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text('חיפוש מהיר לפי שם, מספר אישי או מחלקה (${soldiers.length} חיילים זמינים)',
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                Icon(LucideIcons.chevronDown, color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Text('שגיאה בטעינת חיילים'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24),
                
                HopalFormSection(
                  title: 'תגיות מהירות (הזנה ללא הקלדה)',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickTags.map((tag) {
                        return InkWell(
                          onTap: () => _addTag(tag),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                              border: Border.all(color: AppTheme.primaryGreen),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    HopalTextField(
                      controller: _descController,
                      hint: 'תיאור מילולי חופשי (אופציונלי)...',
                      icon: LucideIcons.fileText,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: AppTheme.radiusMd,
                      child: Container(
                        height: _imagePath == null ? null : 160,
                        padding: _imagePath == null ? const EdgeInsets.all(AppTheme.spacing16) : null,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          border: Border.all(color: AppTheme.borderSubtle, style: BorderStyle.solid, width: 2),
                          borderRadius: AppTheme.radiusMd,
                          image: _imagePath != null
                              ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _imagePath == null 
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.camera, color: AppTheme.textPrimary),
                                  const SizedBox(width: AppTheme.spacing8),
                                  Text('הוסף צילום רפואי (אופציונלי)', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                ],
                              )
                            : Container(
                                alignment: Alignment.bottomCenter,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                  ),
                                  borderRadius: AppTheme.radiusMd,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.checkCircle2, color: AppTheme.successGreen, size: 16),
                                    const SizedBox(width: 8),
                                    Text('תמונה צורפה בהצלחה', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing16),
                    HopalButton(
                      label: 'בקש המלצת טיפול מ-AI Copilot',
                      icon: LucideIcons.sparkles,
                      onPressed: _runCopilot,
                      isExpanded: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24),

                HopalFormSection(
                  title: 'סיווג רפואי וחומרה',
                  children: [
                    Text('קטגוריית תחלואה', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: AppTheme.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundTertiary,
                        borderRadius: AppTheme.radiusMd,
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: AppTheme.backgroundSecondary,
                          icon: Icon(LucideIcons.chevronDown, color: AppTheme.textSecondary),
                          items: ['שגרת מרפאה', 'אורתופדיה', 'טראומה / פציעה', 'מחלות זיהומיות', 'ברה"ן'].map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: TextStyle(color: AppTheme.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text('חומרה / דחיפות', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: AppTheme.spacing8),
                    HopalSegmentedControl(
                      segments: const ['שגרה', 'דחוף', 'חירום'],
                      selectedIndex: ['שגרה', 'דחוף', 'חירום'].indexOf(_selectedSeverity),
                      onValueChanged: (index) {
                        setState(() {
                          _selectedSeverity = ['שגרה', 'דחוף', 'חירום'][index];
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing32),

                Text('החלטת חופ"ל', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.spacing16),
                HopalSegmentedControl(
                  segments: const ['טיפול הושלם', 'נדרש המשך טיפול'],
                  selectedIndex: _selectedOutcome == 'COMPLETED' ? 0 : 1,
                  onValueChanged: (index) {
                    setState(() {
                      _selectedOutcome = index == 0 ? 'COMPLETED' : 'REQUIRES_ATTENTION';
                    });
                  },
                ),
                
                const SizedBox(height: AppTheme.spacing32),
                HopalButton(
                  label: widget.existingCase == null ? 'שמור פנייה' : 'עדכן פנייה',
                  onPressed: _handleCreate,
                  isLoading: _isSaving,
                  icon: LucideIcons.save,
                  isExpanded: true,
                ),
                const SizedBox(height: AppTheme.spacing48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
