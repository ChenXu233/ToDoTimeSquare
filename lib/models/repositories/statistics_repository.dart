import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/schema/focus_records.dart';
import '../dtos/statistics_dto.dart';

part 'statistics_repository.g.dart';

// ========== 累加器类（避免重复创建对象） ==========

/// 每日统计累加器
class _DailyStatsAccumulator {
  DateTime date;
  int focusMinutes = 0;
  int sessions = 0;
  int completedSessions = 0;
  double totalEfficiency = 0;
  int efficiencyCount = 0;

  _DailyStatsAccumulator(this.date);
}

/// 任务专注统计累加器
class _TaskStatsAccumulator {
  String taskId;
  String taskTitle;
  int totalMinutes = 0;
  int sessions = 0;
  DateTime lastRecordTime;

  _TaskStatsAccumulator(this.taskId, this.taskTitle, this.lastRecordTime);
}

/// 统计仓储
/// 提供专注记录的聚合查询，为统计页面和云同步提供数据支持
@DriftAccessor(tables: [FocusRecords])
class StatisticsRepository extends DatabaseAccessor<AppDatabase>
    with _$StatisticsRepositoryMixin {
  StatisticsRepository(super.db);

  // ========== 概览统计 ==========

  /// 获取统计概览（单次查询优化版）
  Future<StatisticsOverviewDTO> getOverview() async {
    // 单次查询获取所有记录
    final query = select(focusRecords)
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)]);

    final rows = await query.get();

    // 在内存中聚合计算
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

    int totalMinutes = 0;
    int todayMinutes = 0;
    int weekMinutes = 0;
    int todaySessions = 0;
    final scores = <double>[];
    DateTime? lastTime;

    for (final row in rows) {
      final minutes = row.durationSeconds ~/ 60;
      totalMinutes += minutes;

      if (row.startTime.isAfter(today)) {
        todayMinutes += minutes;
        todaySessions++;
      }

      if (row.startTime.isAfter(startOfWeek)) {
        weekMinutes += minutes;
      }

      if (row.efficiencyScore != null) {
        scores.add(row.efficiencyScore!);
      }

      if (lastTime == null || row.startTime.isAfter(lastTime)) {
        lastTime = row.startTime;
      }
    }

    return StatisticsOverviewDTO(
      totalFocusMinutes: totalMinutes,
      todayFocusMinutes: todayMinutes,
      thisWeekFocusMinutes: weekMinutes,
      todaySessions: todaySessions,
      totalSessions: rows.length,
      avgEfficiency: scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length,
      lastRecordTime: lastTime,
    );
  }

  // ========== 每日统计 ==========

  /// 获取最近 N 天每日统计（优化版：减少对象创建）
  Future<List<DailyStatisticsDTO>> getDailyStats({int days = 30}) async {
    final query = select(focusRecords)
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)]);

    final rows = await query.get();

    // 按日期分组聚合（使用累加器避免重复创建对象）
    final statsMap = <DateTime, _DailyStatsAccumulator>{};

    for (final row in rows) {
      final date = DateTime(row.startTime.year, row.startTime.month, row.startTime.day);

      final accumulator = statsMap.putIfAbsent(date, () => _DailyStatsAccumulator(date));
      accumulator.focusMinutes += row.durationSeconds ~/ 60;
      accumulator.sessions += 1;
      if (row.isCompleted) accumulator.completedSessions++;

      if (row.efficiencyScore != null) {
        accumulator.totalEfficiency += row.efficiencyScore!;
        accumulator.efficiencyCount++;
      }
    }

    return statsMap.values.map((acc) {
      return DailyStatisticsDTO(
        date: acc.date,
        focusMinutes: acc.focusMinutes,
        sessions: acc.sessions,
        completedSessions: acc.completedSessions,
        efficiency: acc.efficiencyCount > 0 ? acc.totalEfficiency / acc.efficiencyCount : null,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(days)
      .toList();
  }

  // ========== 周趋势统计 ==========

  /// 获取周趋势统计
  Future<WeeklyTrendDTO> getWeeklyTrend() async {
    final dailyStats = await getDailyStats(days: 7);

    final weekTotal = dailyStats.fold(0, (sum, d) => sum + d.focusMinutes);
    final avgDaily = dailyStats.isEmpty ? 0.0 : weekTotal / dailyStats.length;
    final bestDay = dailyStats.isEmpty
        ? 0
        : dailyStats.map((d) => d.focusMinutes).reduce((a, b) => a > b ? a : b);

    // 计算效率趋势
    final efficiencyWithData = dailyStats.where(
        (d) => d.efficiency != null && d.efficiency! > 0);
    final efficiencyTrend = efficiencyWithData.isEmpty
        ? null
        : efficiencyWithData
                .map((d) => d.efficiency!)
                .reduce((a, b) => a + b) /
            efficiencyWithData.length;

    return WeeklyTrendDTO(
      dailyData: dailyStats,
      weekTotalMinutes: weekTotal,
      avgDailyMinutes: avgDaily,
      efficiencyTrend: efficiencyTrend,
      bestDayMinutes: bestDay,
    );
  }

  // ========== 任务关联统计 ==========

  /// 获取按任务聚合的专注统计（优化版）
  Future<List<TaskFocusStatsDTO>> getTaskFocusStats({int limit = 20}) async {
    final query = select(focusRecords)
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)])
      ..limit(100); // 获取足够数据

    final rows = await query.get();

    // 按 taskId 分组（使用累加器）
    final statsMap = <String, _TaskStatsAccumulator>{};

    for (final row in rows) {
      if (row.taskId == null) continue;

      final accumulator = statsMap.putIfAbsent(
        row.taskId!,
        () => _TaskStatsAccumulator(
          row.taskId!,
          row.taskTitle ?? '未知任务',
          row.startTime,
        ),
      );

      accumulator.totalMinutes += row.durationSeconds ~/ 60;
      accumulator.sessions += 1;
      if (row.startTime.isAfter(accumulator.lastRecordTime)) {
        accumulator.lastRecordTime = row.startTime;
      }
    }

    // 转换为 DTO 列表并排序
    final result = statsMap.values.map((acc) {
      return TaskFocusStatsDTO(
        taskId: acc.taskId,
        taskTitle: acc.taskTitle,
        totalMinutes: acc.totalMinutes,
        sessions: acc.sessions,
        lastRecordTime: acc.lastRecordTime,
      );
    }).toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes))
      ..take(limit);

    return result.toList();
  }

  // ========== 辅助查询 ==========

  /// 获取总专注时长（分钟）
  Future<int> getTotalFocusMinutes() async {
    final query = selectOnly(focusRecords)
      ..addColumns([focusRecords.durationSeconds]);
    final rows = await query.get();
    return rows.fold<int>(
        0, (sum, row) => sum + (row.read(focusRecords.durationSeconds) ?? 0)) ~/
        60;
  }

  /// 获取总专注次数
  Future<int> getTotalSessions() async {
    final query = select(focusRecords);
    final rows = await query.get();
    return rows.length;
  }

  /// 获取指定日期范围的专注记录
  Future<List<FocusRecord>> getRecordsInRange(DateTime start, DateTime end) async {
    final query = select(focusRecords)
      ..where((r) =>
          r.startTime.isBiggerThanValue(start) & r.startTime.isSmallerThanValue(end))
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)]);
    return await query.get();
  }
}
