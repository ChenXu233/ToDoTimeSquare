import 'package:flutter/material.dart';
import '../models/database/database_initializer.dart';
import '../models/repositories/statistics_repository.dart';
import '../models/repositories/task_statistics_repository.dart';
import '../models/repositories/focus_record_repository.dart';
import '../models/dtos/statistics_dto.dart';

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

  late final StatisticsRepository _statsRepository;
  late final TaskStatisticsRepository _taskStatsRepository;
  late final FocusRecordRepository _focusRecordRepository;

  StatisticsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final db = DatabaseInitializer().database;
    _statsRepository = StatisticsRepository(db);
    _taskStatsRepository = TaskStatisticsRepository(db);
    _focusRecordRepository = FocusRecordRepository(db);
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
}
