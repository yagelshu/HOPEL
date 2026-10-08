import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
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

  User? _currentUser;
  User? get currentUser => _currentUser;
  
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

  final _supabase = supa.Supabase.instance.client;

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

  Future<String?> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await loadProfile();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'name': name,
            'role': 'COMBAT_MEDIC',
            'unit_id': null, // User must select or create a unit after login
          });
        } catch (dbError) {
          print('DB Insert error (probably RLS or Email Confirmation): $dbError');
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
      return 'Unknown error during sign up';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    
    // Clear local database to prevent data leak between users
    final db = await DatabaseService().database;
    await db.clear();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } catch (e) {
      return e.toString();
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
