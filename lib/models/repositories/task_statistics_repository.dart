import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/schema/todos.dart';
import '../dtos/statistics_dto.dart';

part 'task_statistics_repository.g.dart';

// ========== 累加器类 ==========

/// 每日任务统计累加器
class _DayTaskStatsAccumulator {
  DateTime date;
  int created = 0;
  int completed = 0;

  _DayTaskStatsAccumulator(this.date);
}

/// 任务统计仓储
/// 提供任务相关的统计查询，支持任务完成率分析
@DriftAccessor(tables: [Todos])
class TaskStatisticsRepository extends DatabaseAccessor<AppDatabase>
    with _$TaskStatisticsRepositoryMixin {
  TaskStatisticsRepository(super.db);

  // ========== 任务完成率统计 ==========

  /// 获取任务完成率统计
  Future<TaskCompletionStatsDTO> getTaskCompletionStats() async {
    final allTasks = await getAllTasks();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final createdToday = allTasks
        .where((t) =>
            t.createdAt.isAfter(todayStart) ||
            t.createdAt.isAtSameMomentAs(todayStart))
        .length;
    final completedToday = completedTasks
        .where((t) => t.completedAt != null && t.completedAt!.isAfter(todayStart))
        .length;

    // 按重要性分组
    final byImportance = <int, int>{};
    for (final task in allTasks) {
      byImportance[task.importance] = (byImportance[task.importance] ?? 0) + 1;
    }

    return TaskCompletionStatsDTO(
      totalTasks: allTasks.length,
      completedTasks: completedTasks.length,
      createdToday: createdToday,
      completedToday: completedToday,
      byImportance: byImportance,
      completionRate: allTasks.isEmpty ? 0 : completedTasks.length / allTasks.length,
    );
  }

  /// 按重要性获取任务统计
  Future<Map<int, int>> getTasksByImportance() async {
    final allTasks = await getAllTasks();
    final result = <int, int>{};

    for (final task in allTasks) {
      result[task.importance] = (result[task.importance] ?? 0) + 1;
    }

    return result;
  }

  // ========== 任务完成趋势统计 ==========

  /// 获取任务完成率趋势（单次查询优化版）
  Future<List<TaskCompletionTrendDTO>> getCompletionTrend({int days = 7}) async {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: days - 1));
    final startOfStart = DateTime(startDate.year, startDate.month, startDate.day);

    // 单次查询获取日期范围内的所有任务
    final allTasks = await (select(todos)
          ..where((t) => t.createdAt.isBiggerThanValue(startOfStart)))
        .get();

    // 初始化日期映射
    final dailyMap = <DateTime, _DayTaskStatsAccumulator>{};
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final dayDate = DateTime(date.year, date.month, date.day);
      dailyMap[dayDate] = _DayTaskStatsAccumulator(dayDate);
    }

    // 统计创建和完成
    for (final task in allTasks) {
      // 统计创建
      final createdDate = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );
      if (dailyMap.containsKey(createdDate)) {
        dailyMap[createdDate]!.created += 1;
      }

      // 统计完成
      if (task.completedAt != null) {
        final completedDate = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        if (dailyMap.containsKey(completedDate)) {
          dailyMap[completedDate]!.completed += 1;
        }
      }
    }

    return dailyMap.values.map((acc) {
      return TaskCompletionTrendDTO(
        date: acc.date,
        created: acc.created,
        completed: acc.completed,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ========== 辅助方法 ==========

  /// 获取所有任务
  Future<List<Todo>> getAllTasks() async {
    return await select(todos).get();
  }

  /// 获取已完成任务
  Future<List<Todo>> getCompletedTasks() async {
    final query = select(todos)
      ..where((t) => t.isCompleted.equals(true));
    return await query.get();
  }

  /// 获取未完成任务
  Future<List<Todo>> getPendingTasks() async {
    final query = select(todos)
      ..where((t) => t.isCompleted.equals(false));
    return await query.get();
  }
}
