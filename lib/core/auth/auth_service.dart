import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/auth/web_biometrics.dart';

class User {
  final String id;
  final String name;
  final String role;
  final String? unitId;
  final String? unitName;
  final String? unitJoinCode;
  final String? activeDeploymentId;
  final String? activeDeploymentName;
  final int competencePoints;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.unitId,
    this.unitName,
    this.unitJoinCode,
    this.activeDeploymentId,
    this.activeDeploymentName,
    this.competencePoints = 0,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'] ?? 'משתמש',
      role: map['role'] ?? 'COMBAT_MEDIC',
      unitId: map['unit_id'],
      unitName: map['unit_name'],
      unitJoinCode: map['unit_join_code'],
      activeDeploymentId: map['active_deployment_id'],
      activeDeploymentName: map['active_deployment_name'],
      competencePoints: map['competence_points'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'unit_id': unitId,
      'unit_name': unitName,
      'unit_join_code': unitJoinCode,
      'active_deployment_id': activeDeploymentId,
      'active_deployment_name': activeDeploymentName,
      'competence_points': competencePoints,
    };
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  static const String defaultWebRedirectUrl = 'https://yagelshu.github.io/HOPEL/';

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Allows a COMPANY_MEDIC (חופ"ל) to preview the exact UI and permissions of a COMBAT_MEDIC.
  final ValueNotifier<bool> previewAsCombatMedicNotifier = ValueNotifier<bool>(false);

  bool get isActualCompanyMedic => _currentUser?.role == 'COMPANY_MEDIC';
  bool get isPreviewingAsCombatMedic => isActualCompanyMedic && previewAsCombatMedicNotifier.value;
  String get effectiveRole =>
      isPreviewingAsCombatMedic ? 'COMBAT_MEDIC' : (_currentUser?.role ?? 'COMBAT_MEDIC');
  bool get isCompanyMedic => effectiveRole == 'COMPANY_MEDIC';

  void setCombatMedicPreview(bool enabled) {
    previewAsCombatMedicNotifier.value = enabled && isActualCompanyMedic;
  }

  /// True when the app was opened from a password recovery link
  bool isPasswordRecovery = false;

  /// Optional auth error message captured from redirect URL hash/query (e.g. expired recovery link)
  String? pendingAuthErrorMessage;

  String? _extractRecoveryAmrTimestamp() {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;
    try {
      final parts = session.accessToken.split('.');
      if (parts.length != 3) return null;
      final payloadStr = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      final amr = payload['amr'];
      if (amr is List) {
        for (final entry in amr) {
          if (entry is Map && entry['method'] == 'recovery') {
            return entry['timestamp']?.toString() ?? 'recovery';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Inspects the active Supabase JWT `amr` claim to detect a recovery session
  /// even when URL fragments were stripped or PKCE `?code=` was used.
  Future<void> checkInitialRecoverySession() async {
    final ts = _extractRecoveryAmrTimestamp();
    if (ts == null) return;

    final prefs = await SharedPreferences.getInstance();
    final handledTs = prefs.getString('handled_recovery_amr_ts');
    if (ts == handledTs) return;

    final parsedSeconds = int.tryParse(ts);
    if (parsedSeconds != null) {
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if ((nowSeconds - parsedSeconds).abs() > 3600) {
        return;
      }
    }

    isPasswordRecovery = true;
  }

  /// Marks the current recovery session as completed so it doesn't prompt again.
  Future<void> markRecoveryHandled() async {
    isPasswordRecovery = false;
    final ts = _extractRecoveryAmrTimestamp();
    if (ts != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('handled_recovery_amr_ts', ts);
    }
  }

  void updateCurrentUserDeployment(String? deploymentId, String? deploymentName) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        role: _currentUser!.role,
        unitId: _currentUser!.unitId,
        unitName: _currentUser!.unitName,
        unitJoinCode: _currentUser!.unitJoinCode,
        activeDeploymentId: deploymentId,
        activeDeploymentName: deploymentName,
        competencePoints: _currentUser!.competencePoints,
      );
      _saveLocalProfile(_currentUser!.toMap());
    }
  }

  void updateCurrentUserUnit(String unitId, String unitName, String joinCode, {String? role}) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        role: role ?? _currentUser!.role,
        unitId: unitId,
        unitName: unitName,
        unitJoinCode: joinCode,
        activeDeploymentId: _currentUser!.activeDeploymentId,
        activeDeploymentName: _currentUser!.activeDeploymentName,
        competencePoints: _currentUser!.competencePoints,
      );
      _saveLocalProfile(_currentUser!.toMap());
    }
  }

  void updateCompetencePoints(int additionalPoints) {
    if (_currentUser != null) {
      final newPoints = _currentUser!.competencePoints + additionalPoints;
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        role: _currentUser!.role,
        unitId: _currentUser!.unitId,
        unitName: _currentUser!.unitName,
        unitJoinCode: _currentUser!.unitJoinCode,
        activeDeploymentId: _currentUser!.activeDeploymentId,
        activeDeploymentName: _currentUser!.activeDeploymentName,
        competencePoints: newPoints,
      );
      _saveLocalProfile(_currentUser!.toMap());
    }
  }

  supa.SupabaseClient get _supabase => supa.Supabase.instance.client;

  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Fetch user profile from the `users` table based on Auth ID
  Future<void> loadProfile() async {
    final supaUser = _supabase.auth.currentUser;
    if (supaUser == null) {
      _currentUser = null;
      previewAsCombatMedicNotifier.value = false;
      return;
    }

    try {
      final data = await _supabase
          .from('users')
          .select('id, name, role, unit_id, active_deployment_id, competence_points, units(name, join_code), deployments(name)')
          .eq('id', supaUser.id)
          .maybeSingle();

      if (data == null) {
        final fallback = await _loadLocalProfile(supaUser.id) ??
            User(
              id: supaUser.id,
              name: supaUser.email?.split('@').first ?? 'חופ"ל',
              role: 'COMBAT_MEDIC',
            );
        _currentUser = fallback;
        try {
          await _supabase.from('users').upsert({
            'id': fallback.id,
            'name': fallback.name,
            'role': fallback.role,
            'unit_id': fallback.unitId,
            'active_deployment_id': fallback.activeDeploymentId,
          });
        } catch (_) {}
        return;
      }

      final map = Map<String, dynamic>.from(data);
      if (map['units'] != null) {
        map['unit_name'] = map['units']['name'];
        map['unit_join_code'] = map['units']['join_code'];
      }
      if (map['deployments'] != null) {
        map['active_deployment_name'] = map['deployments']['name'];
      }
      _currentUser = User.fromMap(map);

      // Self-heal if a unit founder's role was previously overwritten to COMBAT_MEDIC
      // leaving the unit without any COMPANY_MEDIC.
      if (_currentUser != null &&
          _currentUser!.unitId != null &&
          _currentUser!.role != 'COMPANY_MEDIC') {
        try {
          final existingChiefs = await _supabase
              .from('users')
              .select('id')
              .eq('unit_id', _currentUser!.unitId!)
              .eq('role', 'COMPANY_MEDIC')
              .limit(1);
          if ((existingChiefs as List).isEmpty) {
            await _supabase
                .from('users')
                .update({'role': 'COMPANY_MEDIC'})
                .eq('id', _currentUser!.id);
            map['role'] = 'COMPANY_MEDIC';
            _currentUser = User.fromMap(map);
          }
        } catch (_) {}
      }

      if (!isActualCompanyMedic) {
        previewAsCombatMedicNotifier.value = false;
      }
      await _saveLocalProfile(map);
    } catch (e) {
      debugPrint('AuthService.loadProfile error: $e');
      _currentUser = await _loadLocalProfile(supaUser.id) ?? User(id: supaUser.id, name: 'משתמש חדש', role: 'COMBAT_MEDIC');
    }
  }

  Future<void> _saveLocalProfile(Map<String, dynamic> profileMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_${profileMap['id']}', jsonEncode(profileMap));
  }

  Future<User?> _loadLocalProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_profile_$userId');
    if (data != null) {
      try {
        return User.fromMap(jsonDecode(data));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Translates technical Supabase / network exceptions into clean, user-friendly Hebrew.
  static String localizeAuthError(Object error) {
    String code = '';
    String message = '';
    String? statusCode;

    if (error is supa.AuthException) {
      code = (error.code ?? '').toLowerCase();
      message = error.message.toLowerCase();
      statusCode = error.statusCode;
    } else {
      message = error.toString().toLowerCase();
    }

    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('user already registered') ||
        message.contains('already registered') ||
        message.contains('already been registered') ||
        message.contains('user_already_exists')) {
      return 'משתמש עם כתובת אימייל זו כבר קיים במערכת. עבור להתחברות או אפס סיסמה.';
    }

    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'האימייל או הסיסמה שגויים. בדוק את הפרטים ונסה שוב.';
    }

    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return 'כתובת האימייל טרם אומתה. בדוק את תיבת הדואר שלך (כולל ספאם).';
    }

    if (code == 'weak_password' ||
        message.contains('password should be at least') ||
        message.contains('weak_password')) {
      return 'הסיסמה קצרה או חלשה מדי – יש לבחור סיסמה בת 6 תווים לפחות.';
    }

    if (code == 'same_password' ||
        message.contains('different from the old password') ||
        message.contains('same_password')) {
      return 'הסיסמה החדשה חייבת להיות שונה מהסיסמה הנוכחית.';
    }

    if (code == 'validation_failed' ||
        code == 'invalid_email' ||
        message.contains('unable to validate email') ||
        message.contains('invalid format') ||
        message.contains('validate email address')) {
      return 'כתובת האימייל שהוזנה אינה תקינה.';
    }

    if (statusCode == '429' ||
        code.contains('rate_limit') ||
        message.contains('rate limit') ||
        message.contains('only request this after') ||
        message.contains('too many requests')) {
      return 'נשלחו יותר מדי בקשות בזמן קצר. אנא המתן כדקה ונסה שוב.';
    }

    if (code == 'otp_expired' ||
        code == 'flow_state_expired' ||
        message.contains('invalid or has expired') ||
        message.contains('token has expired')) {
      return 'פג תוקף הקישור לאיפוס הסיסמה. בקש קישור חדש במסך ההתחברות.';
    }

    if (code == 'user_not_found' || message.contains('user not found')) {
      return 'לא נמצא משתמש עם כתובת אימייל זו.';
    }

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('failed to fetch') ||
        message.contains('clientexception') ||
        message.contains('xmlhttprequest') ||
        message.contains('network')) {
      return 'אין חיבור לאינטרנט. בדוק את הקליטה ונסה שוב.';
    }

    debugPrint('Unhandled Auth Error: $error');
    return 'אירעה שגיאה בתקשורת מול השרת. אנא נסה שוב בעוד רגע.';
  }

  String _resolvePasswordResetRedirectUrl() {
    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocal = host == 'localhost' || host == '127.0.0.1';
      if (!isLocal && Uri.base.origin.startsWith('http')) {
        return '${Uri.base.origin}${Uri.base.path}';
      }
    }
    return defaultWebRedirectUrl;
  }

  Future<String?> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await loadProfile();
      return null;
    } catch (e) {
      return localizeAuthError(e);
    }
  }

  Future<String?> register(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null &&
          response.user!.identities != null &&
          response.user!.identities!.isEmpty) {
        return 'משתמש עם כתובת אימייל זו כבר קיים במערכת. עבור להתחברות או אפס סיסמה.';
      }

      if (response.user != null) {
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'name': name,
            'role': 'COMBAT_MEDIC',
            'unit_id': null,
          });
        } catch (dbError) {
          debugPrint('DB Insert error (probably RLS or Email Confirmation): $dbError');
          _currentUser = User(id: response.user!.id, name: name, role: 'COMBAT_MEDIC');
        }
        await loadProfile();

        if (_currentUser?.name == 'משתמש חדש' && name.isNotEmpty) {
          _currentUser = User(id: response.user!.id, name: name, role: 'COMBAT_MEDIC');
          await _saveLocalProfile(_currentUser!.toMap());
        }

        return null;
      }
      return 'לא ניתן היה להשלים את ההרשמה כרגע. נסה שוב.';
    } catch (e) {
      return localizeAuthError(e);
    }
  }

  Future<void> logout() async {
    isPasswordRecovery = false;
    previewAsCombatMedicNotifier.value = false;
    await _supabase.auth.signOut();
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_password');

    final db = await DatabaseService().database;
    await db.clear();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _resolvePasswordResetRedirectUrl(),
      );
      return null;
    } catch (e) {
      return localizeAuthError(e);
    }
  }

  void updateUnitAndDeploymentNames({String? unitName, String? deploymentName}) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        role: _currentUser!.role,
        unitId: _currentUser!.unitId,
        unitName: unitName ?? _currentUser!.unitName,
        unitJoinCode: _currentUser!.unitJoinCode,
        activeDeploymentId: _currentUser!.activeDeploymentId,
        activeDeploymentName: deploymentName ?? _currentUser!.activeDeploymentName,
        competencePoints: _currentUser!.competencePoints,
      );
      _saveLocalProfile(_currentUser!.toMap());
    }
  }

  Future<void> detachFromCurrentUnit() async {
    final user = _currentUser;
    if (user == null) return;

    previewAsCombatMedicNotifier.value = false;

    await _supabase.from('users').update({
      'unit_id': null,
      'active_deployment_id': null,
    }).eq('id', user.id);

    _currentUser = User(
      id: user.id,
      name: user.name,
      role: user.role,
      unitId: null,
      unitName: null,
      unitJoinCode: null,
      activeDeploymentId: null,
      activeDeploymentName: null,
      competencePoints: user.competencePoints,
    );
    await _saveLocalProfile(_currentUser!.toMap());

    try {
      final db = await DatabaseService().database;
      await db.clear();
    } catch (_) {}
  }

  Future<bool> canUseBiometrics() async {
    if (kIsWeb) {
      return await WebBiometrics.isAvailable();
    }
    final LocalAuthentication auth = LocalAuthentication();
    try {
      return await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Enables biometric lock. Returns `null` on success, or a clear Hebrew error string.
  Future<String?> enableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      final result = await WebBiometrics.register(
        userId: _currentUser?.id ?? 'hopal-user',
        userName: _currentUser?.name ?? 'חופ"ל',
      );
      if (result.startsWith('OK:')) {
        final credId = result.substring(3);
        await prefs.setString('webauthn_credential_id', credId);
        await prefs.setBool('use_biometrics', true);
        return null;
      }
      if (result.contains('NotAllowedError')) {
        return 'הסריקה הביומטרית בוטלה או שלא מוגדרת נעילת מסך/טביעת אצבע במכשיר.';
      }
      if (result.contains('SecurityError') || result.contains('UNSUPPORTED')) {
        return 'דפדפן פנימי זה חוסם גישה לחיישן הביומטרי – פתח את הקישור ישירות בדפדפן Chrome / Safari.';
      }
      return 'לא ניתן היה להפעיל זיהוי ביומטרי בדפדפן זה. ודא שהאתר פתוח ב-Chrome או Safari.';
    }

    final verified = await authenticateWithBiometrics();
    if (!verified) {
      return 'האימות הביומטרי לא הושלם. ודא שמוגדרת טביעת אצבע או זיהוי פנים במכשיר.';
    }
    await prefs.setBool('use_biometrics', true);
    return null;
  }

  Future<void> disableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometrics', false);
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final credId = prefs.getString('webauthn_credential_id');
      return await WebBiometrics.authenticate(credId);
    }

    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      return await auth.authenticate(
        localizedReason: 'הזדהה על מנת להתחבר למערכת חופ"ל',
      );
    } catch (e) {
      return false;
    }
  }
}
