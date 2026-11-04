import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:chopel_app/core/database/database_service.dart';

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

  /// True when the app was opened from a password recovery link
  bool isPasswordRecovery = false;
  
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

  void updateCurrentUserUnit(String unitId, String unitName, String joinCode) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        role: _currentUser!.role,
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
      return;
    }

    try {
      final data = await _supabase
          .from('users')
          .select('id, name, role, unit_id, active_deployment_id, competence_points, units(name, join_code), deployments(name)')
          .eq('id', supaUser.id)
          .maybeSingle();
          
      if (data == null) {
        _currentUser = await _loadLocalProfile(supaUser.id) ?? User(id: supaUser.id, name: 'משתמש חדש', role: 'COMBAT_MEDIC');
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
      await _saveLocalProfile(map);
    } catch (e) {
      print('AuthService.loadProfile error: $e');
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

    // 1. Existing user / email already registered
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('user already registered') ||
        message.contains('already registered') ||
        message.contains('already been registered') ||
        message.contains('user_already_exists')) {
      return 'משתמש עם כתובת אימייל זו כבר קיים במערכת. עבור להתחברות או אפס סיסמה.';
    }

    // 2. Wrong email or password
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'האימייל או הסיסמה שגויים. בדוק את הפרטים ונסה שוב.';
    }

    // 3. Unconfirmed email
    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return 'כתובת האימייל טרם אומתה. בדוק את תיבת הדואר שלך (כולל ספאם).';
    }

    // 4. Weak password
    if (code == 'weak_password' ||
        message.contains('password should be at least') ||
        message.contains('weak_password')) {
      return 'הסיסמה קצרה או חלשה מדי – יש לבחור סיסמה בת 6 תווים לפחות.';
    }

    // 5. Same password during reset
    if (code == 'same_password' ||
        message.contains('different from the old password') ||
        message.contains('same_password')) {
      return 'הסיסמה החדשה חייבת להיות שונה מהסיסמה הנוכחית.';
    }

    // 6. Invalid email format
    if (code == 'validation_failed' ||
        code == 'invalid_email' ||
        message.contains('unable to validate email') ||
        message.contains('invalid format') ||
        message.contains('validate email address')) {
      return 'כתובת האימייל שהוזנה אינה תקינה.';
    }

    // 7. Rate limit / too many attempts
    if (statusCode == '429' ||
        code.contains('rate_limit') ||
        message.contains('rate limit') ||
        message.contains('only request this after') ||
        message.contains('too many requests')) {
      return 'נשלחו יותר מדי בקשות בזמן קצר. אנא המתן כדקה ונסה שוב.';
    }

    // 8. Expired / invalid recovery link
    if (code == 'otp_expired' ||
        code == 'flow_state_expired' ||
        message.contains('invalid or has expired') ||
        message.contains('token has expired')) {
      return 'פג תוקף הקישור לאיפוס הסיסמה. בקש קישור חדש במסך ההתחברות.';
    }

    // 9. User not found
    if (code == 'user_not_found' || message.contains('user not found')) {
      return 'לא נמצא משתמש עם כתובת אימייל זו.';
    }

    // 10. Network / Offline connectivity
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

      // When "Confirm email" is enabled in Supabase, signing up with an already-registered
      // email returns a user object with an empty `identities` list instead of throwing.
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
            'unit_id': null, // User must select or create a unit after login
          });
        } catch (dbError) {
          debugPrint('DB Insert error (probably RLS or Email Confirmation): $dbError');
          // Fallback user state
          _currentUser = User(id: response.user!.id, name: name, role: 'COMBAT_MEDIC');
        }
        await loadProfile();
        
        // If loadProfile fails to find the record (because insert failed), use the fallback
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
    await _supabase.auth.signOut();
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_password');
    
    // Clear local database to prevent data leak between users
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

  Future<bool> authenticateWithBiometrics() async {
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
