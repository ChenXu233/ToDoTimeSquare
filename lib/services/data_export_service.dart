import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/database/app_database.dart';
import '../models/export/export_config.dart';
import '../models/repositories/todo_repository.dart';
import '../models/repositories/focus_record_repository.dart';
import '../models/repositories/habit_repository.dart';
import '../models/repositories/habit_log_repository.dart';

/// 数据导出服务
/// 提供 JSON 和 CSV 格式的数据导出功能
class DataExportService {
  final AppDatabase db;

  DataExportService({required this.db});

  /// 导出数据
  Future<ExportResult> export(ExportConfig config) async {
    if (!config.validate()) {
      return ExportResult.failure('Invalid export configuration');
    }

    try {
      // 收集所有要导出的数据
      final allData = <String, dynamic>{};
      int totalRecords = 0;

      for (final dataType in config.dataTypes) {
        final filteredData = await _getFilteredData(dataType, config);
        if (filteredData.isEmpty) continue;

        allData[_getDataTypeKey(dataType)] = filteredData;
        totalRecords += _countRecords(filteredData);
      }

      if (allData.isEmpty) {
        return ExportResult.failure('No data to export');
      }

      // 生成文件内容
      final String fileContent;
      final String extension;

      switch (config.format) {
        case ExportFormat.json:
          fileContent = _toJson(allData);
          extension = 'json';
          break;
        case ExportFormat.csv:
          fileContent = _toCsv(allData);
          extension = 'csv';
          break;
      }

      // 选择保存路径
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final defaultFileName = 'todotimesquare_export_$timestamp.$extension';

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Export File',
        fileName: defaultFileName,
      );

      if (outputPath == null) {
        return ExportResult.failure('User cancelled file selection');
      }

      // 写入文件
      final file = File(outputPath);
      await file.writeAsString(fileContent);

      return ExportResult.success(outputPath, totalRecords);
    } catch (e) {
      return ExportResult.failure(e.toString());
    }
  }

  /// 获取筛选后的数据
  Future<List<Map<String, dynamic>>> _getFilteredData(
    ExportDataType dataType,
    ExportConfig config,
  ) async {
    switch (dataType) {
      case ExportDataType.todos:
        return await _exportTodos(config);
      case ExportDataType.focusRecords:
        return await _exportFocusRecords(config);
      case ExportDataType.habits:
        return await _exportHabits(config);
      case ExportDataType.habitLogs:
        return await _exportHabitLogs(config);
    }
  }

  /// 导出待办事项
  Future<List<Map<String, dynamic>>> _exportTodos(ExportConfig config) async {
    final repository = TodoRepository(db);
    final allTasks = await repository.getAllTasks();

    return allTasks
        .map((task) => {
              'id': task.id,
              'title': task.title,
              'description': task.description,
              'estimatedDuration': task.estimatedDuration,
              'importance': task.importance,
              'importanceLabel': _getImportanceLabel(task.importance),
              'plannedStartTime': task.plannedStartTime?.toIso8601String(),
              'isCompleted': task.isCompleted,
              'parentId': task.parentId,
              'createdAt': task.createdAt.toIso8601String(),
              'updatedAt': task.updatedAt.toIso8601String(),
              'completedAt': task.completedAt?.toIso8601String(),
            })
        .where((task) => _isInDateRange(task['createdAt'], config))
        .toList();
  }

  /// 导出专注记录
  Future<List<Map<String, dynamic>>> _exportFocusRecords(
    ExportConfig config,
  ) async {
    final repository = FocusRecordRepository(db);
    final allRecords = await repository.getAllRecords();

    return allRecords
        .map((record) => {
              'id': record.id,
              'taskId': record.taskId,
              'taskTitle': record.taskTitle,
              'startTime': record.startTime.toIso8601String(),
              'durationSeconds': record.durationSeconds,
              'durationMinutes': record.durationMinutes,
              'isCompleted': record.isCompleted,
              'interruptionCount': record.interruptionCount,
              'efficiencyScore': record.efficiencyScore,
              'createdAt': record.createdAt.toIso8601String(),
            })
        .where((record) => _isInDateRange(record['startTime'], config))
        .toList();
  }

  /// 导出习惯
  Future<List<Map<String, dynamic>>> _exportHabits(ExportConfig config) async {
    final repository = HabitRepository(db);
    final allHabits = await repository.getAllHabits();

    return allHabits
        .map((habit) => {
              'id': habit.id,
              'name': habit.name,
              'description': habit.description,
              'targetType': habit.targetType,
              'targetTypeLabel': _getTargetTypeLabel(habit.targetType),
              'targetValue': habit.targetValue,
              'color': habit.color,
              'icon': habit.icon,
              'isActive': habit.isActive,
              'createdAt': habit.createdAt.toIso8601String(),
              'archivedAt': habit.archivedAt?.toIso8601String(),
            })
        .where((habit) => _isInDateRange(habit['createdAt'], config))
        .toList();
  }

  /// 导出习惯打卡记录
  Future<List<Map<String, dynamic>>> _exportHabitLogs(
    ExportConfig config,
  ) async {
    final repository = HabitLogRepository(db);
    final allLogs = await repository.getAllLogs();

    return allLogs
        .map((log) => {
              'id': log.id,
              'habitId': log.habitId,
              'date': log.date.toIso8601String(),
              'completedValue': log.completedValue,
              'notes': log.notes,
              'createdAt': log.createdAt.toIso8601String(),
            })
        .where((log) => _isInDateRange(log['date'], config))
        .toList();
  }

  /// 转换为 JSON 格式
  String _toJson(Map<String, dynamic> data) {
    final exportData = {
      'exportInfo': {
        'appName': 'Todo Time Square',
        'exportTime': DateTime.now().toIso8601String(),
        'version': '0.7.3',
      },
      'data': data,
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 转换为 CSV 格式
  String _toCsv(Map<String, dynamic> data) {
    final lines = <String>[];

    for (final entry in data.entries) {
      final key = entry.key;
      final items = entry.value as List<Map<String, dynamic>>;

      if (items.isEmpty) continue;

      // 添加分组标题
      lines.add('### $key ###');
      lines.add('');

      // 添加表头
      final headers = items.first.keys.toList();
      lines.add(headers.join(','));

      // 添加数据行
      for (final item in items) {
        final values = headers.map((header) {
          final value = item[header];
          return _escapeCsvValue(value);
        }).join(',');
        lines.add(values);
      }

      lines.add('');
    }

    return lines.join('\n');
  }

  /// 转义 CSV 值
  String _escapeCsvValue(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// 检查是否在日期范围内
  bool _isInDateRange(dynamic dateStr, ExportConfig config) {
    if (dateStr == null) return true;
    if (dateStr is! String) return true;
    final date = DateTime.parse(dateStr);

    if (config.startDate != null && date.isBefore(config.startDate!)) {
      return false;
    }
    if (config.endDate != null && date.isAfter(config.endDate!)) {
      return false;
    }
    return true;
  }

  /// 计算记录数
  int _countRecords(List<Map<String, dynamic>> data) {
    return data.length;
  }

  /// 获取数据类型键名
  String _getDataTypeKey(ExportDataType type) {
    switch (type) {
      case ExportDataType.todos:
        return 'todos';
      case ExportDataType.focusRecords:
        return 'focusRecords';
      case ExportDataType.habits:
        return 'habits';
      case ExportDataType.habitLogs:
        return 'habitLogs';
    }
  }

  /// 获取重要性标签
  String _getImportanceLabel(int importance) {
    switch (importance) {
      case 0:
        return 'low';
      case 1:
        return 'medium';
      case 2:
        return 'high';
      default:
        return 'unknown';
    }
  }

  /// 获取习惯目标类型标签
  String _getTargetTypeLabel(int targetType) {
    switch (targetType) {
      case 0:
        return 'daily';
      case 1:
        return 'weekly';
      default:
        return 'unknown';
    }
  }
}
