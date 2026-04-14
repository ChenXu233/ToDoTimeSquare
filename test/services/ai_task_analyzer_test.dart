import 'package:flutter_test/flutter_test.dart';
import 'package:todo_time_square/services/ai_task_analyzer.dart';
import 'package:todo_time_square/services/ai_provider.dart';
import 'package:todo_time_square/models/repositories/todo_repository.dart';

// Mock AIProvider
class MockAIProvider implements AIProvider {
  String? responseToReturn;
  bool completeCalled = false;
  String? lastPrompt;

  MockAIProvider({this.responseToReturn});

  @override
  Future<String?> complete(String prompt) async {
    completeCalled = true;
    lastPrompt = prompt;
    return responseToReturn;
  }

  @override
  Stream<String> completeStream(String prompt) async* {
    completeCalled = true;
    lastPrompt = prompt;
    if (responseToReturn != null) {
      yield responseToReturn!;
    }
  }
}

void main() {
  group('AITaskAnalyzer', () {
    group('_buildPrompt', () {
      test('提示词包含任务标题', () {
        final mockProvider = MockAIProvider();
        final analyzer = AITaskAnalyzer(mockProvider);

        // 通过 analyzeTask 间接测试 _buildPrompt
        mockProvider.responseToReturn = '{"description":"test","importance":1,"dependencies":[],"estimated_minutes":30}';
        analyzer.analyzeTask('测试任务标题', []);

        expect(mockProvider.lastPrompt, contains('测试任务标题'));
      });

      test('提示词包含现有任务列表', () {
        final mockProvider = MockAIProvider();
        final analyzer = AITaskAnalyzer(mockProvider);

        final existingTasks = [
          TaskModel(
            id: '12345678-0000-0000-0000-000000000001',
            title: '已完成任务',
            importance: 1,
            isCompleted: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        mockProvider.responseToReturn = '{"description":"test","importance":1,"dependencies":[],"estimated_minutes":30}';
        analyzer.analyzeTask('新任务', existingTasks);

        expect(mockProvider.lastPrompt, contains('已完成任务'));
        expect(mockProvider.lastPrompt, contains('12345678')); // ID 前8位
      });

      test('空任务列表时不包含现有任务参考', () {
        final mockProvider = MockAIProvider();
        final analyzer = AITaskAnalyzer(mockProvider);

        mockProvider.responseToReturn = '{"description":"test","importance":1,"dependencies":[],"estimated_minutes":30}';
        analyzer.analyzeTask('新任务', []);

        expect(mockProvider.lastPrompt, isNot(contains('现有任务参考')));
      });
    });

    group('_parseResponse', () {
      test('解析正常 JSON', () async {
        final mockProvider = MockAIProvider(
          responseToReturn: '{"description":"测试描述","importance":2,"dependencies":["12345678"],"estimated_minutes":60}',
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        final result = await analyzer.analyzeTask('测试任务', []);

        expect(result, isNotNull);
        expect(result!.description, '测试描述');
        expect(result.importance, TodoImportance.high);
        expect(result.dependencies, ['12345678']);
        expect(result.estimatedMinutes, 60);
      });

      test('解析 Markdown JSON 代码块 (```json)', () async {
        final mockProvider = MockAIProvider(
          responseToReturn: '''
```json
{"description":"Markdown解析测试","importance":0,"dependencies":[],"estimated_minutes":15}
```
''',
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        final result = await analyzer.analyzeTask('测试', []);

        expect(result, isNotNull);
        expect(result!.description, 'Markdown解析测试');
        expect(result.importance, TodoImportance.low);
      });

      test('解析带换行的普通 JSON', () async {
        // 不带 markdown 代码块标记的纯 JSON（可能有换行）
        final mockProvider = MockAIProvider(
          responseToReturn: '  \n{"description":"普通JSON","importance":1,"dependencies":[],"estimated_minutes":30}\n  ',
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        final result = await analyzer.analyzeTask('测试', []);

        expect(result, isNotNull);
        expect(result!.description, '普通JSON');
      });

      test('解析失败返回 null', () async {
        final mockProvider = MockAIProvider(
          responseToReturn: '这不是有效的 JSON',
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        final result = await analyzer.analyzeTask('测试', []);

        expect(result, isNull);
      });

      test('AI 返回 null 时 analyzeTask 返回 null', () async {
        final mockProvider = MockAIProvider(
          responseToReturn: null,
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        final result = await analyzer.analyzeTask('测试', []);

        expect(result, isNull);
      });
    });

    group('TaskAnalysisResult.fromJson', () {
      test('正常反序列化', () {
        final json = {
          'description': '测试描述',
          'importance': 2,
          'dependencies': ['id1', 'id2'],
          'estimated_minutes': 45,
        };

        final result = TaskAnalysisResult.fromJson(json);

        expect(result.description, '测试描述');
        expect(result.importance, TodoImportance.high);
        expect(result.dependencies, ['id1', 'id2']);
        expect(result.estimatedMinutes, 45);
      });

      test('缺少可选字段使用默认值', () {
        final json = <String, dynamic>{
          'description': '只有必需字段',
        };

        final result = TaskAnalysisResult.fromJson(json);

        expect(result.description, '只有必需字段');
        expect(result.importance, TodoImportance.medium); // 默认值
        expect(result.dependencies, isEmpty);
        expect(result.estimatedMinutes, isNull);
      });

      test('null 字段使用默认值', () {
        final json = {
          'description': null,
          'importance': null,
          'dependencies': null,
          'estimated_minutes': null,
        };

        final result = TaskAnalysisResult.fromJson(json);

        expect(result.description, ''); // null ?? ''
        expect(result.importance, TodoImportance.medium); // clamp 后的默认值
        expect(result.dependencies, isEmpty);
        expect(result.estimatedMinutes, isNull);
      });

      test('importance 越界被 clamp', () {
        final json1 = {'description': 'test', 'importance': -1};
        final json2 = {'description': 'test', 'importance': 99};

        final result1 = TaskAnalysisResult.fromJson(json1);
        final result2 = TaskAnalysisResult.fromJson(json2);

        expect(result1.importance, TodoImportance.low); // clamp 到 0
        expect(result2.importance, TodoImportance.high); // clamp 到 2
      });
    });

    group('analyzeTask 集成测试', () {
      test('完整流程：标题 + 现有任务 -> AI 分析 -> 解析结果', () async {
        final mockProvider = MockAIProvider(
          responseToReturn: '''
```json
{
  "description": "这是一个由 AI 分析的任务描述",
  "importance": 2,
  "dependencies": ["11111111"],
  "estimated_minutes": 120
}
```
''',
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        final existingTasks = [
          TaskModel(
            id: '11111111-1111-1111-1111-111111111111',
            title: '前置任务',
            importance: 1,
            isCompleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final result = await analyzer.analyzeTask('新任务', existingTasks);

        expect(result, isNotNull);
        expect(result!.description, '这是一个由 AI 分析的任务描述');
        expect(result.importance, TodoImportance.high);
        expect(result.dependencies, ['11111111']);
        expect(result.estimatedMinutes, 120);

        // 验证 prompt 包含了现有任务
        expect(mockProvider.lastPrompt, contains('前置任务'));
        expect(mockProvider.lastPrompt, contains('11111111'));
      });

      test('AIProvider.complete 被调用', () async {
        final mockProvider = MockAIProvider(
          responseToReturn: '{"description":"test","importance":1,"dependencies":[]}',
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        expect(mockProvider.completeCalled, false);
        await analyzer.analyzeTask('测试', []);
        expect(mockProvider.completeCalled, true);
      });
    });

    group('analyzeTaskStream', () {
      test('流式版本返回相同结果', () async {
        final mockProvider = MockAIProvider(
          responseToReturn: '{"description":"流式测试","importance":0,"dependencies":[],"estimated_minutes":10}',
        );
        final analyzer = AITaskAnalyzer(mockProvider);

        final results = <TaskAnalysisResult?>[];
        await for (final result in analyzer.analyzeTaskStream('测试', [])) {
          results.add(result);
        }

        expect(results.length, 1);
        expect(results[0]!.description, '流式测试');
      });
    });
  });
}
