import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

/// Claude API 配置
class ClaudeConfig {
  static const String defaultBaseUrl = 'https://api.anthropic.com';
  static const String defaultModel = 'claude-3-5-haiku-20241022';
  static const Duration defaultTimeout = Duration(seconds: 30);

  static String baseUrl = defaultBaseUrl;
  static String apiKey = '';
  static String model = defaultModel;
  static Duration timeout = defaultTimeout;

  /// 从环境变量或配置文件加载配置
  static void loadFromEnvironment() {
    // 未来可以从 .env 或 shared_preferences 加载
    // 目前需要手动设置
  }

  /// 更新 API Key
  static void setApiKey(String key) {
    apiKey = key;
  }

  /// 重置为默认配置
  static void reset() {
    baseUrl = defaultBaseUrl;
    apiKey = '';
    model = defaultModel;
    timeout = defaultTimeout;
  }
}

/// Claude API 实现
class ClaudeProvider implements AIProvider {
  final http.Client _client;

  ClaudeProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<String?> complete(String prompt) async {
    if (ClaudeConfig.apiKey.isEmpty) {
      return null;
    }

    try {
      final response = await _client.post(
        Uri.parse('${ClaudeConfig.baseUrl}/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ClaudeConfig.apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: jsonEncode({
          'model': ClaudeConfig.model,
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      ).timeout(ClaudeConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final content = json['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          final firstBlock = content.first as Map<String, dynamic>;
          return firstBlock['text'] as String?;
        }
      }
      return null;
    } catch (e) {
      // 实际应用中应该记录日志
      return null;
    }
  }

  @override
  Stream<String> completeStream(String prompt) async* {
    if (ClaudeConfig.apiKey.isEmpty) {
      return;
    }

    try {
      final response = await _client.post(
        Uri.parse('${ClaudeConfig.baseUrl}/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ClaudeConfig.apiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: jsonEncode({
          'model': ClaudeConfig.model,
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'stream': true,
        }),
      ).timeout(ClaudeConfig.timeout);

      if (response.statusCode == 200) {
        // 处理流式响应
        final lines = const LineSplitter().convert(response.body);
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') break;
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final content = json['content'] as List<dynamic>?;
              if (content != null && content.isNotEmpty) {
                final text = content.first as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            } catch (_) {
              // 忽略解析错误
            }
          }
        }
      }
    } catch (e) {
      // 流式错误处理
    }
  }

  void dispose() {
    _client.close();
  }
}
