// Authentication service for API calls.
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/auth/token.dart';
import '../models/auth/user.dart';

/// 可配置的服务器地址
class AuthServiceConfig {
  static String baseUrl = 'http://localhost:8000';
  static const Duration timeout = Duration(seconds: 30);

  /// 更新服务器地址
  static void updateBaseUrl(String url) {
    baseUrl = url;
  }

  /// 重置为默认地址
  static void resetBaseUrl() {
    baseUrl = 'http://localhost:8000';
  }
}

class AuthService {
  final http.Client? _client;

  /// 获取当前配置的 baseUrl
  String get baseUrl => AuthServiceConfig.baseUrl;

  /// 获取超时时间
  Duration get timeout => AuthServiceConfig.timeout;

  /// 创建 AuthService，可选注入 http.Client 用于测试
  AuthService({http.Client? client}) : _client = client;

  /// 内部使用的 http client
  http.Client get _httpClient => _client ?? http.Client();

  /// Login with username and password
  Future<Token> login(String username, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': username,
        'password': password,
      },
    ).timeout(timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Token.fromJson(json);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(
        error['detail'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    }
  }

  /// Register a new user
  Future<User> register(String username, String email, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    ).timeout(timeout);

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(
        error['detail'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    }
  }

  /// Refresh access token
  Future<Token> refreshToken(String refreshToken) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh_token': refreshToken,
      }),
    ).timeout(timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Token.fromJson(json);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(
        error['detail'] ?? 'Token refresh failed',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get current user info
  Future<User> getCurrentUser(String accessToken) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(
        error['detail'] ?? 'Failed to get user info',
        statusCode: response.statusCode,
      );
    }
  }

  /// Logout (client-side only, clears tokens)
  Future<void> logout() async {
    // In a stateless JWT system, logout is handled client-side
    // The server doesn't need to do anything special
    return Future.value();
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, {this.statusCode = 400});

  @override
  String toString() => 'AuthException: $message (status: $statusCode)';
}
