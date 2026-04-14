import 'dart:convert';
import '../models/repositories/todo_repository.dart';
import 'ai_provider.dart';

/// AI 任务分析结果
class TaskAnalysisResult {
  final String description;
  final TodoImportance importance;
  final List<String> dependencies;
  final int? estimatedMinutes;

  TaskAnalysisResult({
    required this.description,
    required this.importance,
    this.dependencies = const [],
    this.estimatedMinutes,
  });

  factory TaskAnalysisResult.fromJson(Map<String, dynamic> json) {
    return TaskAnalysisResult(
      description: json['description'] as String? ?? '',
      importance: TodoImportance.values[(json['importance'] as int? ?? 1).clamp(0, 2)],
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      estimatedMinutes: json['estimated_minutes'] as int?,
    );
  }
}

/// AI 任务分析服务
/// 负责调用 AI 分析任务并返回结构化结果
class AITaskAnalyzer {
  final AIProvider _provider;

  AITaskAnalyzer(this._provider);

  /// 分析任务
  /// [title] 任务标题
  /// [existingTasks] 现有任务列表，用于识别依赖关系
  /// 返回分析结果，失败时返回 null
  Future<TaskAnalysisResult?> analyzeTask(
    String title,
    List<TaskModel> existingTasks,
  ) async {
    final prompt = _buildPrompt(title, existingTasks);
    final response = await _provider.complete(prompt);

    if (response == null) {
      return null;
    }

    return _parseResponse(response);
  }

  /// 构建分析提示词
  String _buildPrompt(String title, List<TaskModel> existingTasks) {
    final taskList = existingTasks
        .map((t) => '- "${t.title}" (ID: ${t.id.substring(0, 8)})')
        .join('\n');

    return '''你是一个任务管理助手。请分析这个任务并返回结构化信息。

任务：$title

${existingTasks.isNotEmpty ? '现有任务参考：\n$taskList' : ''}

请返回以下 JSON（只返回 JSON，不要其他内容）：
{
  "description": "任务描述（1-2句话）",
  "importance": 0-2（0=低，1=中，2=高）,
  "dependencies": ["相关任务ID的前8位"],
  "estimated_minutes": 预估分钟数
}''';
  }

  /// 解析 AI 响应
  TaskAnalysisResult? _parseResponse(String response) {
    try {
      // 尝试提取 JSON（可能包含在 markdown 代码块中）
      String jsonStr = response.trim();

      // 处理 markdown 代码块
      if (jsonStr.contains("```json")) {
        jsonStr = jsonStr.split("```json").last.split("```").first;
      } else if (jsonStr.contains("```")) {
        jsonStr = jsonStr.split("```").last.split("```").first;
      }

      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TaskAnalysisResult.fromJson(json);
    } catch (e) {
      // 解析失败
      return null;
    }
  }

  /// 分析任务（流式版本）
  /// 返回 Stream 用于实时显示分析进度
  Stream<TaskAnalysisResult?> analyzeTaskStream(
    String title,
    List<TaskModel> existingTasks,
  ) async* {
    final prompt = _buildPrompt(title, existingTasks);

    // 消耗流式响应（用于未来实时显示进度）
    await for (final _ in _provider.completeStream(prompt)) {
      // 目前不输出中间结果，等待完整响应
    }

    // 流式完成后，返回最终结果
    final response = await _provider.complete(prompt);
    if (response != null) {
      yield _parseResponse(response);
    }
  }
}
