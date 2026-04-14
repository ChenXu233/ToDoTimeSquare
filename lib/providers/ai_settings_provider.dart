import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_claude_provider.dart';

class AISettingsProvider extends ChangeNotifier {
  static const String _apiKeyPrefKey = 'claude_api_key';

  String _apiKey = '';
  bool _isLoaded = false;

  String get apiKey => _apiKey;
  bool get isLoaded => _isLoaded;
  bool get hasApiKey => _apiKey.isNotEmpty;

  AISettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPrefKey) ?? '';

    // Apply to ClaudeConfig if we have a key
    if (_apiKey.isNotEmpty) {
      ClaudeConfig.setApiKey(_apiKey);
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;

    final prefs = await SharedPreferences.getInstance();
    if (key.isEmpty) {
      await prefs.remove(_apiKeyPrefKey);
      ClaudeConfig.reset();
    } else {
      await prefs.setString(_apiKeyPrefKey, key);
      ClaudeConfig.setApiKey(key);
    }

    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await setApiKey('');
  }
}
