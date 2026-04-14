import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:todo_time_square/services/auth_service.dart';

void main() {
  group('AuthService', () {
    group('login', () {
      test('成功登录返回 Token', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/auth/login');
          expect(request.method, 'POST');
          expect(request.headers['Content-Type'], 'application/x-www-form-urlencoded');
          // request.body 是 String 格式: username=testuser&password=testpass
          expect(request.body, contains('username=testuser'));
          expect(request.body, contains('password=testpass'));

          return http.Response(
            jsonEncode({
              'access_token': 'access_abc123',
              'refresh_token': 'refresh_xyz789',
              'token_type': 'bearer',
            }),
            200,
          );
        });

        final service = AuthService(client: mockClient);
        final token = await service.login('testuser', 'testpass');

        expect(token.accessToken, 'access_abc123');
        expect(token.refreshToken, 'refresh_xyz789');
        expect(token.tokenType, 'bearer');
      });

      test('400 错误抛出 AuthException', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Invalid input'}),
            400,
          );
        });

        final service = AuthService(client: mockClient);
        expect(
          () => service.login('bad', 'request'),
          throwsA(isA<AuthException>()),
        );
      });

      test('401 错误包含正确状态码和消息', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Invalid credentials'}),
            401,
          );
        });

        final service = AuthService(client: mockClient);
        try {
          await service.login('user', 'wrong');
          fail('Should throw');
        } on AuthException catch (e) {
          expect(e.statusCode, 401);
          expect(e.message, 'Invalid credentials');
        }
      });

      test('500 错误抛出 AuthException', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Server error'}),
            500,
          );
        });

        final service = AuthService(client: mockClient);
        expect(
          () => service.login('user', 'pass'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('register', () {
      test('成功注册返回 User', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/auth/register');
          expect(request.method, 'POST');
          expect(request.headers['Content-Type'], 'application/json');

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['username'], 'newuser');
          expect(body['email'], 'new@test.com');
          expect(body['password'], 'newpass123');

          return http.Response(
            jsonEncode({
              'id': 1,
              'username': 'newuser',
              'email': 'new@test.com',
              'created_at': '2024-01-01T00:00:00Z',
            }),
            201,
          );
        });

        final service = AuthService(client: mockClient);
        final user = await service.register('newuser', 'new@test.com', 'newpass123');

        expect(user.id, 1);
        expect(user.username, 'newuser');
        expect(user.email, 'new@test.com');
        expect(user.createdAt, isNotNull);
      });

      test('注册请求体格式正确', () async {
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('username'), true);
          expect(body.containsKey('email'), true);
          expect(body.containsKey('password'), true);

          return http.Response(
            jsonEncode({'id': 1, 'username': 'test', 'email': 't@t.com'}),
            201,
          );
        });

        final service = AuthService(client: mockClient);
        await service.register('test', 't@t.com', 'pass');
      });

      test('注册失败抛出 AuthException', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Username already exists'}),
            400,
          );
        });

        final service = AuthService(client: mockClient);
        expect(
          () => service.register('existing', 'e@e.com', 'pass'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('refreshToken', () {
      test('成功刷新返回新 Token', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/auth/refresh');
          expect(request.method, 'POST');

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['refresh_token'], 'old_refresh_token');

          return http.Response(
            jsonEncode({
              'access_token': 'new_access_abc123',
              'refresh_token': 'new_refresh_xyz789',
              'token_type': 'bearer',
            }),
            200,
          );
        });

        final service = AuthService(client: mockClient);
        final token = await service.refreshToken('old_refresh_token');

        expect(token.accessToken, 'new_access_abc123');
        expect(token.refreshToken, 'new_refresh_xyz789');
      });

      test('refreshToken 失败抛出 AuthException', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Invalid refresh token'}),
            401,
          );
        });

        final service = AuthService(client: mockClient);
        expect(
          () => service.refreshToken('bad_token'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getCurrentUser', () {
      test('成功获取用户信息', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/users/me');
          expect(request.method, 'GET');
          expect(request.headers['Authorization'], 'Bearer test_token');

          return http.Response(
            jsonEncode({
              'id': 1,
              'username': 'testuser',
              'email': 'test@test.com',
              'created_at': '2024-01-01T00:00:00Z',
            }),
            200,
          );
        });

        final service = AuthService(client: mockClient);
        final user = await service.getCurrentUser('test_token');

        expect(user.id, 1);
        expect(user.username, 'testuser');
        expect(user.email, 'test@test.com');
      });
    });

    group('logout', () {
      test('logout 返回 Future.value()', () async {
        final mockClient = MockClient((request) async {
          fail('Should not call HTTP');
          return http.Response('', 200);
        });

        final service = AuthService(client: mockClient);
        await service.logout();
      });
    });

    group('AuthException', () {
      test('toString 格式正确', () {
        final ex = AuthException('Test error', statusCode: 404);
        expect(ex.toString(), 'AuthException: Test error (status: 404)');
      });

      test('默认状态码为 400', () {
        final ex = AuthException('No status');
        expect(ex.statusCode, 400);
      });

      test('异常消息正确传递', () {
        final ex = AuthException('Custom message', statusCode: 500);
        expect(ex.message, 'Custom message');
        expect(ex.statusCode, 500);
      });
    });
  });
}
