/// Authentication state provider using ChangeNotifier.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth/user.dart';
import '../models/auth/token.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userKey = 'auth_user';

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _accessToken;
  String? _refreshToken;
  User? _currentUser;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadSavedAuth();
  }

  /// Load saved authentication data from SharedPreferences
  Future<void> _loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);

      if (_accessToken != null && _refreshToken != null) {
        _isLoggedIn = true;
        // Optionally refresh the user data from server
        try {
          _currentUser = await _authService.getCurrentUser(_accessToken!);
        } catch (e) {
          // Token might be expired, try refreshing
          if (_refreshToken != null) {
            await _refreshTokens();
          } else {
            await logout();
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved auth: $e');
    }
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(username, password);
      _accessToken = token.accessToken;
      _refreshToken = token.refreshToken;
      _isLoggedIn = true;

      // Get user info
      _currentUser = await _authService.getCurrentUser(_accessToken!);

      // Save to SharedPreferences
      await _saveAuth();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AuthException ? e.message : 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new user
  Future<bool> register(String username, String email, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(username, email, password);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AuthException ? e.message : 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh access token
  Future<bool> _refreshTokens() async {
    if (_refreshToken == null) return false;

    try {
      final token = await _authService.refreshToken(_refreshToken!);
      _accessToken = token.accessToken;
      _refreshToken = token.refreshToken;
      await _saveAuth();
      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Logout and clear all auth data
  Future<void> logout() async {
    _isLoading = false;
    _isLoggedIn = false;
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _errorMessage = null;

    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);

    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Save auth data to SharedPreferences
  Future<void> _saveAuth() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_accessTokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    }
    if (_currentUser != null) {
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  /// Get authorization header value
  String? getAuthorizationHeader() {
    if (_accessToken == null) return null;
    return 'Bearer $_accessToken';
  }
}
