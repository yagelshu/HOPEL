import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark; // default until loaded
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getBool('isLightMode') ?? false;
    if (isLight) {
      state = ThemeMode.light;
      AppTheme.setLightMode();
    } else {
      state = ThemeMode.dark;
      AppTheme.setDarkMode();
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      AppTheme.setLightMode();
      await prefs.setBool('isLightMode', true);
    } else {
      state = ThemeMode.dark;
      AppTheme.setDarkMode();
      await prefs.setBool('isLightMode', false);
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
