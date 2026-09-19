import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'English';

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // ⭐️ Load saved settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('admin_darkMode') ?? false;
    _language = prefs.getString('admin_language') ?? 'English';
    notifyListeners();
  }

  // ⭐️ Toggle dark mode
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_darkMode', value);
  }

  // ⭐️ Set language
  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_language', value);
  }
}