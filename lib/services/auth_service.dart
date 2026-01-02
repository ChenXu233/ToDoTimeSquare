// Authentication service for API calls.
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/auth/token.dart';
import '../models/auth/user.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration timeout = Duration(seconds: 30);

  /// Login with username and password
  Future<Token> login(String username, String password) async {
    final response = await http.post(
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
    final response = await http.post(
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
    final response = await http.post(
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
    final response = await http.get(
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
