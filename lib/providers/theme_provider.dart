import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _darkMode = false;
  Locale _currentLocale = const Locale('zh', '');

  bool get darkMode => _darkMode;
  Locale get currentLocale => _currentLocale;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    final String? languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      _currentLocale = Locale(languageCode, '');
    }
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    notifyListeners();
  }

  Future<void> changeLanguage(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    notifyListeners();
  }
}
