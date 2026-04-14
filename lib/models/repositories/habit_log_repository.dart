import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/schema/habit_logs.dart';
import '../entities/habit_log_model.dart';

part 'habit_log_repository.g.dart';

/// 习惯打卡记录仓储
/// 提供打卡记录的 CRUD 操作和统计查询
@DriftAccessor(tables: [HabitLogs])
class HabitLogRepository extends DatabaseAccessor<AppDatabase>
    with _$HabitLogRepositoryMixin {
  HabitLogRepository(super.db);

  // ========== 基础 CRUD ==========

  /// 获取所有打卡记录
  Future<List<HabitLogEntity>> getAllLogs() async {
    final query = select(habitLogs)
      ..orderBy([
        (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(HabitLogEntity.fromRow).toList();
  }

  /// 按习惯 ID 获取打卡记录
  Future<List<HabitLogEntity>> getLogsByHabitId(String habitId) async {
    final query = select(habitLogs)
      ..where((l) => l.habitId.equals(habitId))
      ..orderBy([
        (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(HabitLogEntity.fromRow).toList();
  }

  /// 按 ID 获取打卡记录
  Future<HabitLogEntity?> getLogById(String id) async {
    final query = select(habitLogs)..where((l) => l.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? HabitLogEntity.fromRow(row) : null;
  }

  /// 检查某习惯某天是否已打卡
  Future<bool> isCheckedIn(String habitId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = select(habitLogs)
      ..where((l) => l.habitId.equals(habitId))
      ..where((l) {
        final dateExpr = l.date;
        return dateExpr.year.equals(dateOnly.year) &
            dateExpr.month.equals(dateOnly.month) &
            dateExpr.day.equals(dateOnly.day);
      });
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  // ========== 插入操作 ==========

  /// 打卡（创建或更新记录）
  Future<void> checkIn(HabitLogEntity log) async {
    // 检查是否已存在该日期的记录
    final exists = await isCheckedIn(log.habitId, log.date);

    if (exists) {
      // 更新现有记录 - 使用日期比较而非时间比较
      final existingLogs = await getLogsByHabitId(log.habitId);
      final logDateOnly = DateTime(log.date.year, log.date.month, log.date.day);
      final existing = existingLogs.firstWhere(
        (l) => l.date.year == logDateOnly.year &&
               l.date.month == logDateOnly.month &&
               l.date.day == logDateOnly.day,
        orElse: () => throw StateError('Record not found for date $logDateOnly'),
      );
      final updated = log.copyWith(id: existing.id);
      await updateLog(updated);
    } else {
      // 插入新记录
      final entity = log.toCompanion();
      await into(habitLogs).insert(entity);
    }
  }

  // ========== 更新操作 ==========

  /// 更新打卡记录
  Future<bool> updateLog(HabitLogEntity log) async {
    final entity = log.toCompanion();
    final result = await update(habitLogs).replace(entity);
    return result;
  }

  // ========== 删除操作 ==========

  /// 删除打卡记录
  Future<void> deleteLog(String id) async {
    await (delete(habitLogs)..where((l) => l.id.equals(id))).go();
  }

  /// 删除某习惯的所有打卡记录
  Future<void> deleteLogsByHabitId(String habitId) async {
    await (delete(habitLogs)..where((l) => l.habitId.equals(habitId))).go();
  }

  // ========== 统计查询 ==========

  /// 获取某习惯的总打卡次数
  Future<int> getTotalCheckIns(String habitId) async {
    final query = select(habitLogs)
      ..where((l) => l.habitId.equals(habitId));
    final rows = await query.get();
    return rows.length;
  }

  /// 获取今日打卡的记录
  Future<List<HabitLogEntity>> getTodayLogs() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final query = select(habitLogs)
      ..where((l) => l.date.isBiggerOrEqualValue(today) & l.date.isSmallerThanValue(tomorrow))
      ..orderBy([
        (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(HabitLogEntity.fromRow).toList();
  }

  /// 获取指定习惯在指定日期范围内的打卡记录
  Future<List<HabitLogEntity>> getLogsInRange(String habitId, DateTime start, DateTime end) async {
    final query = select(habitLogs)
      ..where((l) => l.habitId.equals(habitId))
      ..where((l) => l.date.isBiggerOrEqualValue(start) & l.date.isSmallerOrEqualValue(end))
      ..orderBy([
        (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(HabitLogEntity.fromRow).toList();
  }

  /// 获取某习惯的连续打卡天数
  Future<int> getStreakDays(String habitId) async {
    final logs = await getLogsByHabitId(habitId);
    if (logs.isEmpty) return 0;

    // 获取今天或昨天的记录作为起点
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 按日期排序（从新到旧），去重
    final sortedDates = logs.map((l) {
      return DateTime(l.date.year, l.date.month, l.date.day);
    }).toSet().toList()..sort((a, b) => b.compareTo(a));

    // 检查今天或昨天是否有记录（streak 不能断超过 1 天）
    final latestDate = sortedDates.first;
    final daysSinceLatest = today.difference(latestDate).inDays;

    // 如果超过1天没打卡，streak 为 0
    if (daysSinceLatest > 1) {
      return 0;
    }

    // 从最新日期开始计算连续天数
    int streak = 1;
    DateTime expectedPreviousDate = latestDate.subtract(const Duration(days: 1));

    for (int i = 1; i < sortedDates.length; i++) {
      final currentDate = sortedDates[i];

      if (currentDate == expectedPreviousDate) {
        // 连续，streak 加 1
        streak++;
        expectedPreviousDate = currentDate.subtract(const Duration(days: 1));
      } else if (currentDate.isBefore(expectedPreviousDate)) {
        // 日期更早但不是连续的前一天，streak 保持，但更新期望日期
        expectedPreviousDate = currentDate.subtract(const Duration(days: 1));
        // 重新计算：如果当前日期和期望日期之间差距超过1天，则断开
        if (expectedPreviousDate.difference(currentDate).inDays > 1) {
          break;
        }
      } else {
        // 同一日期（重复记录），跳过
        continue;
      }
    }

    return streak;
  }

  /// 获取某习惯最近 N 天的打卡记录
  Future<List<DateTime>> getRecentCheckInDates(String habitId, int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));

    final logs = await getLogsInRange(habitId, startDate, now);

    return logs.map((l) {
      return DateTime(l.date.year, l.date.month, l.date.day);
    }).toSet().toList();
  }

  /// 获取某习惯的完成率（最近 N 天）
  Future<double> getCompletionRate(String habitId, int days) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: days - 1));

    final logs = await getLogsInRange(habitId, startDate, today);

    // 计算实际打卡天数（去重）
    final checkedDates = logs.map((l) {
      return DateTime(l.date.year, l.date.month, l.date.day);
    }).toSet();

    return checkedDates.length / days;
  }
}
