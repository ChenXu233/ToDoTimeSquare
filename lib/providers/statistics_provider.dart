import 'package:flutter/material.dart';
import '../models/database/database_initializer.dart';
import '../models/repositories/statistics_repository.dart';
import '../models/repositories/task_statistics_repository.dart';
import '../models/repositories/focus_record_repository.dart';
import '../models/repositories/habit_repository.dart';
import '../models/repositories/habit_log_repository.dart';
import '../models/dtos/statistics_dto.dart';
import '../models/entities/habit_model.dart';
import '../models/entities/habit_log_model.dart';

/// 统计页面 Provider
/// 使用 Repository 层获取统计数据，支持云同步扩展
class StatisticsProvider extends ChangeNotifier {
  StatisticsOverviewDTO? _overview;
  List<DailyStatisticsDTO> _dailyStats = [];
  WeeklyTrendDTO? _weeklyTrend;
  TaskCompletionStatsDTO? _taskStats;
  List<TaskFocusStatsDTO> _taskFocusList = [];
  List<TaskCompletionTrendDTO> _completionTrend = [];

  bool _isLoading = true;
  String? _error;

  // Getters
  StatisticsOverviewDTO? get overview => _overview;
  List<DailyStatisticsDTO> get dailyStats => _dailyStats;
  WeeklyTrendDTO? get weeklyTrend => _weeklyTrend;
  TaskCompletionStatsDTO? get taskStats => _taskStats;
  List<TaskFocusStatsDTO> get taskFocusList => _taskFocusList;
  List<TaskCompletionTrendDTO> get completionTrend => _completionTrend;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 向后兼容：records 列表
  List<FocusRecordModel> _records = [];
  List<FocusRecordModel> get records => _records;
  List<FocusRecordModel> get recentRecords => _records.take(20).toList();

  // ========== 习惯相关数据 ==========
  List<HabitEntity> _habits = [];
  List<HabitEntity> _todayCheckedInHabits = []; // 今日已打卡习惯
  Map<String, int> _habitStreaks = {}; // 习惯ID -> 连续打卡天数
  Map<String, int> _habitTotalCheckIns = {}; // 习惯ID -> 总打卡次数

  // Getters
  List<HabitEntity> get habits => _habits;
  List<HabitEntity> get todayCheckedInHabits => _todayCheckedInHabits;
  List<HabitEntity> get habitsNotCheckedInToday =>
      _habits.where((h) => !_todayCheckedInHabits.any((c) => c.id == h.id)).toList();
  int get checkedInTodayCount => _todayCheckedInHabits.length;
  int get totalActiveHabits => _habits.length;

  late final StatisticsRepository _statsRepository;
  late final TaskStatisticsRepository _taskStatsRepository;
  late final FocusRecordRepository _focusRecordRepository;
  late final HabitRepository _habitRepository;
  late final HabitLogRepository _habitLogRepository;

  StatisticsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final db = DatabaseInitializer().database;
    _statsRepository = StatisticsRepository(db);
    _taskStatsRepository = TaskStatisticsRepository(db);
    _focusRecordRepository = FocusRecordRepository(db);
    _habitRepository = HabitRepository(db);
    _habitLogRepository = HabitLogRepository(db);
    await loadAllData();
  }

  /// 加载所有统计数据
  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadOverview(notify: false),
        loadDailyStats(notify: false),
        loadWeeklyTrend(notify: false),
        loadTaskStats(notify: false),
        loadTaskFocusList(notify: false),
        loadCompletionTrend(notify: false),
        loadRecords(notify: false),
        loadHabits(notify: false),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== 数据加载方法（统一通知控制） ==========

  /// 加载统计概览
  Future<void> loadOverview({bool notify = true}) async {
    _overview = await _statsRepository.getOverview();
    if (notify) notifyListeners();
  }

  /// 加载每日统计
  Future<void> loadDailyStats({int days = 30, bool notify = true}) async {
    _dailyStats = await _statsRepository.getDailyStats(days: days);
    if (notify) notifyListeners();
  }

  /// 加载周趋势
  Future<void> loadWeeklyTrend({bool notify = true}) async {
    _weeklyTrend = await _statsRepository.getWeeklyTrend();
    if (notify) notifyListeners();
  }

  /// 加载任务统计
  Future<void> loadTaskStats({bool notify = true}) async {
    _taskStats = await _taskStatsRepository.getTaskCompletionStats();
    if (notify) notifyListeners();
  }

  /// 加载任务专注列表
  Future<void> loadTaskFocusList({int limit = 20, bool notify = true}) async {
    _taskFocusList = await _statsRepository.getTaskFocusStats(limit: limit);
    if (notify) notifyListeners();
  }

  /// 加载完成趋势
  Future<void> loadCompletionTrend({int days = 7, bool notify = true}) async {
    _completionTrend = await _taskStatsRepository.getCompletionTrend(days: days);
    if (notify) notifyListeners();
  }

  /// 加载记录列表（向后兼容）
  Future<void> loadRecords({bool notify = true}) async {
    _records = await _focusRecordRepository.getAllRecords();
    _records.sort((a, b) => b.startTime.compareTo(a.startTime));
    if (notify) notifyListeners();
  }

  // ========== 向后兼容方法 ==========

  /// 添加专注记录（向后兼容方法）
  Future<void> addRecord(FocusRecordModel record) async {
    _records.insert(0, record);
    notifyListeners();
    await _focusRecordRepository.createRecord(record);
  }

  // ========== 计算属性 ==========

  /// 获取今日专注时长（分钟）
  int get todayFocusMinutes => _overview?.todayFocusMinutes ?? 0;

  /// 获取累计专注时长（分钟）
  int get totalFocusMinutes => _overview?.totalFocusMinutes ?? 0;

  /// 获取本周专注时长（分钟）
  int get thisWeekFocusMinutes => _overview?.thisWeekFocusMinutes ?? 0;

  /// 获取今日专注次数
  int get todaySessions => _overview?.todaySessions ?? 0;

  /// 获取任务完成率
  double get taskCompletionRate => _taskStats?.completionRate ?? 0.0;

  /// 获取任务完成率百分比
  String get taskCompletionRatePercent =>
      '${(taskCompletionRate * 100).toStringAsFixed(1)}%';

  /// 获取最高重要性任务数
  int get highImportanceTaskCount =>
      _taskStats?.byImportance[3] ?? 0;

  /// 获取过去7天的数据用于图表（兼容旧接口）
  List<DailyStatisticsDTO> get last7DaysData {
    if (_dailyStats.length >= 7) {
      return _dailyStats.sublist(0, 7);
    }
    return _dailyStats;
  }

  // ========== 习惯相关方法 ==========

  /// 加载习惯列表
  Future<void> loadHabits({bool notify = true}) async {
    _habits = await _habitRepository.getActiveHabits();
    await _loadHabitStats();
    if (notify) notifyListeners();
  }

  /// 加载习惯统计数据
  Future<void> _loadHabitStats() async {
    _habitStreaks = {};
    _habitTotalCheckIns = {};
    _todayCheckedInHabits = [];

    for (final habit in _habits) {
      final streak = await _habitLogRepository.getStreakDays(habit.id);
      final total = await _habitLogRepository.getTotalCheckIns(habit.id);
      _habitStreaks[habit.id] = streak;
      _habitTotalCheckIns[habit.id] = total;

      // 检查今日是否已打卡
      final isCheckedIn = await _habitLogRepository.isCheckedIn(habit.id, DateTime.now());
      if (isCheckedIn) {
        _todayCheckedInHabits.add(habit);
      }
    }
  }

  /// 打卡习惯
  Future<void> checkInHabit(String habitId) async {
    final now = DateTime.now();

    final log = HabitLogEntity(
      id: '${habitId}_${now.millisecondsSinceEpoch}',
      habitId: habitId,
      date: now,
      completedValue: 1,
      createdAt: now,
    );

    await _habitLogRepository.checkIn(log);

    // 重新加载数据
    await loadHabits(notify: true);
  }

  /// 取消打卡
  Future<void> uncheckHabit(String habitId) async {
    final logs = await _habitLogRepository.getLogsByHabitId(habitId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 找到今天的记录并删除
    final todayLog = logs.firstWhere(
      (l) => l.date.year == today.year &&
             l.date.month == today.month &&
             l.date.day == today.day,
      orElse: () => throw Exception('今日未打卡'),
    );

    await _habitLogRepository.deleteLog(todayLog.id);

    // 重新加载数据
    await loadHabits(notify: true);
  }

  /// 创建新习惯
  Future<void> createHabit({
    required String name,
    String? description,
    int targetType = 0,
    int targetValue = 1,
    String? color,
    String? icon,
  }) async {
    final habit = HabitEntity(
      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      targetType: targetType,
      targetValue: targetValue,
      color: color ?? '#4CAF50', // 默认绿色
      icon: icon,
      isActive: true,
      createdAt: DateTime.now(),
      archivedAt: null,
    );

    await _habitRepository.createHabit(habit);
    await loadHabits(notify: true);
  }

  /// 更新习惯
  Future<void> updateHabit(HabitEntity habit) async {
    await _habitRepository.updateHabit(habit);
    await loadHabits(notify: true);
  }

  /// 删除习惯
  Future<void> deleteHabit(String habitId) async {
    // 先删除打卡记录
    await _habitLogRepository.deleteLogsByHabitId(habitId);
    // 再删除习惯
    await _habitRepository.deleteHabit(habitId);
    await loadHabits(notify: true);
  }

  /// 归档习惯
  Future<void> archiveHabit(String habitId) async {
    await _habitRepository.archiveHabit(habitId);
    await loadHabits(notify: true);
  }

  /// 获取习惯连续打卡天数
  int getHabitStreak(String habitId) => _habitStreaks[habitId] ?? 0;

  /// 获取习惯总打卡次数
  int getHabitTotalCheckIns(String habitId) => _habitTotalCheckIns[habitId] ?? 0;

  /// 检查习惯今日是否已打卡
  bool isHabitCheckedInToday(String habitId) =>
      _todayCheckedInHabits.any((h) => h.id == habitId);
}
