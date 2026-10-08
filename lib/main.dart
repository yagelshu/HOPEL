import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chopel_app/core/database/database_service.dart';

import 'package:chopel_app/screens/splash_screen.dart';
import 'package:chopel_app/screens/biometric_lock_screen.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:chopel_app/theme/theme_provider.dart';
import 'package:chopel_app/features/auth/update_password_screen.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    await Supabase.initialize(
      url: 'https://ffnrvjoswyphsduvmhbe.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZmbnJ2am9zd3lwaHNkdXZtaGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2NjI3MDIsImV4cCI6MjEwMTIzODcwMn0.kUelONEPeHZESu6TWwNc-S75uZxV4g0z0HYwjcChFvQ',
    );

    await DatabaseService().database;

    runApp(const ProviderScope(child: HopalApp()));
  } catch (e, stackTrace) {
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Startup Error:\n$e\n\nStackTrace:\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class HopalApp extends ConsumerStatefulWidget {
  const HopalApp({super.key});

  @override
  ConsumerState<HopalApp> createState() => _HopalAppState();
}

class _HopalAppState extends ConsumerState<HopalApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AuthState> _authSubscription;
  DateTime? _lastPausedTime;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastPausedTime != null) {
        final diff = DateTime.now().difference(_lastPausedTime!);
        if (diff.inMinutes >= 2) {
          _checkAndLockApp();
        }
        _lastPausedTime = null;
      }
    }
  }

  Future<void> _checkAndLockApp() async {
    if (_isLocked) return;
    
    final prefs = await SharedPreferences.getInstance();
    final useBiometrics = prefs.getBool('use_biometrics') ?? false;
    
    if (useBiometrics && AuthService().isAuthenticated) {
      _isLocked = true;
      await _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const BiometricLockScreen()),
      );
      _isLocked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'חופ״ל',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'),
      ],
      locale: const Locale('he', 'IL'),
      home: const SplashScreen(),
    );
  }
}


