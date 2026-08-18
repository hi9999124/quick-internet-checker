import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const _themeKey = 'qic_theme_mode_v1';
  static const _unitsKey = 'qic_units_mbps_v1';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<bool> loadUseMbps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unitsKey) ?? true;
  }

  Future<void> saveUseMbps(bool useMbps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unitsKey, useMbps);
  }
}
