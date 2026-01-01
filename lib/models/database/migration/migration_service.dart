import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_database.dart';
import '../migrations/legacy_models/todo.dart' as old_todo;
import '../migrations/legacy_models/focus_record.dart' as old_focus;

/// 数据迁移服务
/// 将 SharedPreferences 中的数据迁移到 Drift 数据库
class MigrationService {
  final AppDatabase _db;

  MigrationService(this._db);

  /// 执行完整迁移
  /// 返回迁移结果：success=成功数量, failed=失败数量
  Future<MigrationResult> migrateAll() async {
    final result = MigrationResult();
    result.todosMigrated = await _migrateTodos();
    result.focusRecordsMigrated = await _migrateFocusRecords();
    return result;
  }

  /// 迁移 Todo 数据
  Future<int> _migrateTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosString = prefs.getString('todos');

    if (todosString == null) return 0;

    try {
      final List<dynamic> todosJson = jsonDecode(todosString);
      final oldTodos = todosJson.map((json) => old_todo.Todo.fromJson(json)).toList();

      int migrated = 0;
      for (final oldTodo in oldTodos) {
        final entity = TodosCompanion(
          id: Value(oldTodo.id),
          title: Value(oldTodo.title),
          description: oldTodo.description != null ? Value(oldTodo.description!) : const Value.absent(),
          estimatedDuration: oldTodo.estimatedDuration != null
              ? Value(oldTodo.estimatedDuration!.inMinutes)
              : const Value.absent(),
          importance: Value(oldTodo.importance.index + 1), // enum index 0,1,2 -> int 1,2,3
          plannedStartTime: oldTodo.plannedStartTime != null
              ? Value(oldTodo.plannedStartTime!)
              : const Value.absent(),
          isCompleted: Value(oldTodo.isCompleted),
          parentId: oldTodo.parentId != null ? Value(oldTodo.parentId!) : const Value.absent(),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          completedAt: oldTodo.isCompleted ? Value(DateTime.now()) : const Value.absent(),
        );

        await _db.todos.insertOnConflictUpdate(entity);
        migrated++;
      }

      // 迁移成功后清除旧数据
      await prefs.remove('todos');
      return migrated;
    } catch (e) {
      return 0;
    }
  }

  /// 迁移专注记录数据
  Future<int> _migrateFocusRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? recordsJson = prefs.getStringList('focus_records');

    if (recordsJson == null) return 0;

    try {
      final oldRecords = recordsJson
          .map((jsonStr) => old_focus.FocusRecord.fromJson(jsonStr))
          .toList();

      int migrated = 0;
      for (final oldRecord in oldRecords) {
        // 从旧模型推断新字段
        final interruptionCount = _estimateInterruptionCount(oldRecord);
        final efficiencyScore = _calculateEfficiencyScore(oldRecord);

        final entity = FocusRecordsCompanion(
          id: Value(oldRecord.id),
          taskId: oldRecord.taskId != null ? Value(oldRecord.taskId!) : const Value.absent(),
          taskTitle: oldRecord.taskTitle != null ? Value(oldRecord.taskTitle!) : const Value.absent(),
          startTime: Value(oldRecord.startTime),
          durationSeconds: Value(oldRecord.durationSeconds),
          isCompleted: const Value(false), // 旧数据无法确定完成状态
          interruptionCount: Value(interruptionCount),
          efficiencyScore: Value(efficiencyScore),
          createdAt: Value(oldRecord.createdAt),
        );

        await _db.focusRecords.insertOnConflictUpdate(entity);
        migrated++;
      }

      // 迁移成功后清除旧数据
      await prefs.remove('focus_records');
      return migrated;
    } catch (e) {
      return 0;
    }
  }

  /// 根据记录特征估算中断次数
  int _estimateInterruptionCount(old_focus.FocusRecord record) {
    // 基于经验估算：专注时间越长，可能中断次数越多
    // 这是一个粗略估计，旧数据没有这个字段
    final durationMinutes = record.durationSeconds / 60;
    if (durationMinutes < 15) {
      return 0;
    } else if (durationMinutes < 30) {
      return 1;
    } else {
      return (durationMinutes / 15).floor();
    }
  }

  /// 计算效率评分
  /// 基于专注时长与理想番茄钟时长的比例
  double? _calculateEfficiencyScore(old_focus.FocusRecord record) {
    final durationMinutes = record.durationSeconds / 60;
    // 理想番茄钟是25分钟，超过或接近这个时间效率较高
    if (durationMinutes < 5) return null; // 太短不计算效率
    if (durationMinutes >= 20 && durationMinutes <= 35) {
      return 0.9 + (durationMinutes % 5) * 0.02; // 0.9-1.0
    } else if (durationMinutes >= 15 && durationMinutes < 20) {
      return 0.7 + (durationMinutes - 15) * 0.04; // 0.7-0.9
    } else {
      return 0.5 + (durationMinutes - 5) * 0.02; // 0.5-0.8
    }
  }

  /// 检查是否需要迁移（存在旧数据）
  Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final hasTodos = prefs.getString('todos') != null;
    final hasRecords = prefs.getStringList('focus_records') != null;
    return hasTodos || hasRecords;
  }
}

/// 迁移结果
class MigrationResult {
  int todosMigrated = 0;
  int focusRecordsMigrated = 0;

  bool get hasMigratedData => todosMigrated > 0 || focusRecordsMigrated > 0;
  int get totalMigrated => todosMigrated + focusRecordsMigrated;

  @override
  String toString() {
    return '迁移完成：任务 $todosMigrated 条，记录 $focusRecordsMigrated 条';
  }
}
