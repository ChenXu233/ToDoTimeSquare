import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _currentLocale = const Locale('zh', '');

  ThemeMode get themeMode => _themeMode;
  Locale get currentLocale => _currentLocale;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate old setting if exists
    if (prefs.containsKey('darkMode')) {
      final isDark = prefs.getBool('darkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      await prefs.remove('darkMode');
      await prefs.setInt('themeMode', _themeMode.index);
    } else {
      final int? themeIndex = prefs.getInt('themeMode');
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }
    }

    final String? languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      _currentLocale = Locale(languageCode, '');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> changeLanguage(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    notifyListeners();
  }
}
