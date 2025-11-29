import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _darkMode = false;
  Locale _currentLocale = const Locale('zh', '');

  bool get darkMode => _darkMode;
  Locale get currentLocale => _currentLocale;

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void changeLanguage(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }
}
