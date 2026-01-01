import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/schema/focus_records.dart';

part 'focus_record_repository.g.dart';

/// 专注记录数据模型
class FocusRecordModel {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final DateTime startTime;
  final int durationSeconds;
  final bool isCompleted;
  final int interruptionCount;
  final double? efficiencyScore;
  final DateTime createdAt;

  FocusRecordModel({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.startTime,
    required this.durationSeconds,
    required this.isCompleted,
    required this.interruptionCount,
    this.efficiencyScore,
    required this.createdAt,
  });

  /// 获取分钟数
  int get durationMinutes => durationSeconds ~/ 60;

  /// 从数据库行转换
  factory FocusRecordModel.fromRow(FocusRecord row) {
    return FocusRecordModel(
      id: row.id,
      taskId: row.taskId,
      taskTitle: row.taskTitle,
      startTime: row.startTime,
      durationSeconds: row.durationSeconds,
      isCompleted: row.isCompleted,
      interruptionCount: row.interruptionCount,
      efficiencyScore: row.efficiencyScore,
      createdAt: row.createdAt,
    );
  }

  /// 转换为 Insertable
  Insertable<FocusRecord> toCompanion() {
    return FocusRecordsCompanion(
      id: Value(id),
      taskId: taskId != null ? Value(taskId!) : const Value.absent(),
      taskTitle: taskTitle != null ? Value(taskTitle!) : const Value.absent(),
      startTime: Value(startTime),
      durationSeconds: Value(durationSeconds),
      isCompleted: Value(isCompleted),
      interruptionCount: Value(interruptionCount),
      efficiencyScore: efficiencyScore != null ? Value(efficiencyScore!) : const Value.absent(),
      createdAt: Value(createdAt),
    );
  }
}

/// 专注记录仓储
/// 提供专注记录的 CRUD 操作和统计查询
@DriftAccessor(tables: [FocusRecords])
class FocusRecordRepository extends DatabaseAccessor<AppDatabase> with _$FocusRecordRepositoryMixin {
  FocusRecordRepository(super.db);

  // ========== 基础 CRUD ==========

  /// 获取所有记录（按时间倒序）
  Future<List<FocusRecordModel>> getAllRecords() async {
    final query = select(focusRecords)
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)]);
    final rows = await query.get();
    return rows.map(FocusRecordModel.fromRow).toList();
  }

  /// 获取最近 N 条记录
  Future<List<FocusRecordModel>> getRecentRecords(int limit) async {
    final query = select(focusRecords)
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map(FocusRecordModel.fromRow).toList();
  }

  /// 按任务 ID 获取记录
  Future<List<FocusRecordModel>> getRecordsByTaskId(String taskId) async {
    final query = select(focusRecords)
      ..where((r) => r.taskId.equals(taskId))
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)]);
    final rows = await query.get();
    return rows.map(FocusRecordModel.fromRow).toList();
  }

  // ========== 插入操作 ==========

  /// 创建专注记录
  Future<void> createRecord(FocusRecordModel record) async {
    final entity = record.toCompanion();
    await into(focusRecords).insert(entity);
  }

  // ========== 统计查询 ==========

  /// 获取总专注时长（秒）
  Future<int> getTotalFocusSeconds() async {
    final query = selectOnly(focusRecords)
      ..addColumns([focusRecords.durationSeconds]);
    final rows = await query.get();
    int total = 0;
    for (final row in rows) {
      total += row.read(focusRecords.durationSeconds) ?? 0;
    }
    return total;
  }

  /// 获取总专注时长（分钟）
  Future<int> getTotalFocusMinutes() async {
    final seconds = await getTotalFocusSeconds();
    return seconds ~/ 60;
  }

  /// 获取今日专注时长（分钟）
  Future<int> getTodayFocusMinutes() async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tomorrow = today.add(const Duration(days: 1));

    final query = select(focusRecords)
      ..where((r) => r.startTime.isBiggerThanValue(today) & r.startTime.isSmallerThanValue(tomorrow));
    final rows = await query.get();

    return rows.map((row) => row.durationSeconds).fold<int>(0, (a, b) => a + b) ~/ 60;
  }

  /// 获取本周专注时长（分钟）
  Future<int> getThisWeekFocusMinutes() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final query = select(focusRecords)
      ..where((r) => r.startTime.isBiggerThanValue(startOfWeek));
    final rows = await query.get();

    return rows.map((row) => row.durationSeconds).fold<int>(0, (a, b) => a + b) ~/ 60;
  }

  /// 获取今日专注次数
  Future<int> getTodaySessions() async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tomorrow = today.add(const Duration(days: 1));

    final query = select(focusRecords)
      ..where((r) => r.startTime.isBiggerThanValue(today) & r.startTime.isSmallerThanValue(tomorrow));
    final rows = await query.get();
    return rows.length;
  }

  /// 获取按日期聚合的每日数据
  Future<List<DailyFocusStats>> getDailyStats({int limit = 30}) async {
    final query = select(focusRecords)
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.desc)])
      ..limit(limit * 10); // 获取更多数据以确保覆盖

    final rows = await query.get();

    // 按日期分组聚合
    final statsMap = <DateTime, DailyFocusStats>{};

    for (final row in rows) {
      final date = DateTime(row.startTime.year, row.startTime.month, row.startTime.day);

      if (!statsMap.containsKey(date)) {
        statsMap[date] = DailyFocusStats(
          date: date,
          totalSeconds: 0,
          sessions: 0,
          completedSessions: 0,
        );
      }

      final stats = statsMap[date]!;
      statsMap[date] = stats.copyWith(
        totalSeconds: stats.totalSeconds + row.durationSeconds,
        sessions: stats.sessions + 1,
        completedSessions: stats.completedSessions + (row.isCompleted ? 1 : 0),
      );
    }

    return statsMap.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 获取过去 N 天的每日数据（用于图表）
  Future<Map<String, int>> getDailyFocusMinutesForChart(int days) async {
    final stats = await getDailyStats(limit: days);

    final result = <String, int>{};
    for (final stat in stats) {
      final dateStr = '${stat.date.month}-${stat.date.day}';
      result[dateStr] = stat.totalMinutes;
    }

    return result;
  }

  /// 获取效率评分趋势
  Future<List<EfficiencyTrend>> getEfficiencyTrend({int days = 30}) async {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: days));

    final query = select(focusRecords)
      ..where((r) => r.startTime.isBiggerThanValue(startDate))
      ..orderBy([(r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.asc)]);

    final rows = await query.get();

    // 按日期聚合效率评分
    final efficiencyMap = <DateTime, List<double>>{};

    for (final row in rows) {
      if (row.efficiencyScore == null) continue;

      final date = DateTime(row.startTime.year, row.startTime.month, row.startTime.day);
      efficiencyMap.putIfAbsent(date, () => []).add(row.efficiencyScore!);
    }

    return efficiencyMap.entries.map((e) {
      final scores = e.value;
      return EfficiencyTrend(
        date: e.key,
        avgEfficiency: scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length,
        sampleCount: scores.length,
      );
    }).toList();
  }

  // ========== 删除操作 ==========

  /// 删除旧记录（保留最近 N 天）
  Future<int> deleteOldRecords(int daysToKeep) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return await (delete(focusRecords)..where((r) => r.startTime.isSmallerThanValue(cutoffDate)))
        .go();
  }
}

/// 每日专注统计数据
class DailyFocusStats {
  final DateTime date;
  final int totalSeconds;
  final int sessions;
  final int completedSessions;

  DailyFocusStats({
    required this.date,
    required this.totalSeconds,
    required this.sessions,
    required this.completedSessions,
  });

  int get totalMinutes => totalSeconds ~/ 60;

  DailyFocusStats copyWith({
    DateTime? date,
    int? totalSeconds,
    int? sessions,
    int? completedSessions,
  }) {
    return DailyFocusStats(
      date: date ?? this.date,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      sessions: sessions ?? this.sessions,
      completedSessions: completedSessions ?? this.completedSessions,
    );
  }
}

/// 效率趋势数据
class EfficiencyTrend {
  final DateTime date;
  final double avgEfficiency;
  final int sampleCount;

  EfficiencyTrend({
    required this.date,
    required this.avgEfficiency,
    required this.sampleCount,
  });
}
