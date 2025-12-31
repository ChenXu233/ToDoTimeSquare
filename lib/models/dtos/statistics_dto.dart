/// 统计数据传输对象层
/// 为统计页面提供类型安全的数据结构，便于云同步序列化
library;

import 'package:equatable/equatable.dart';

/// 统计概览 DTO
class StatisticsOverviewDTO extends Equatable {
  final int totalFocusMinutes; // 累计专注（分钟）
  final int todayFocusMinutes; // 今日专注（分钟）
  final int thisWeekFocusMinutes; // 本周专注（分钟）
  final int todaySessions; // 今日专注次数
  final int totalSessions; // 累计专注次数
  final double? avgEfficiency; // 平均效率评分
  final DateTime? lastRecordTime; // 最后记录时间

  const StatisticsOverviewDTO({
    required this.totalFocusMinutes,
    required this.todayFocusMinutes,
    required this.thisWeekFocusMinutes,
    required this.todaySessions,
    required this.totalSessions,
    this.avgEfficiency,
    this.lastRecordTime,
  });

  /// 从 JSON 反序列化（云同步用）
  factory StatisticsOverviewDTO.fromJson(Map<String, dynamic> json) {
    return StatisticsOverviewDTO(
      totalFocusMinutes: json['totalFocusMinutes'] as int,
      todayFocusMinutes: json['todayFocusMinutes'] as int,
      thisWeekFocusMinutes: json['thisWeekFocusMinutes'] as int,
      todaySessions: json['todaySessions'] as int,
      totalSessions: json['totalSessions'] as int,
      avgEfficiency: json['avgEfficiency'] as double?,
      lastRecordTime: json['lastRecordTime'] != null
          ? DateTime.parse(json['lastRecordTime'] as String)
          : null,
    );
  }

  /// 序列化为 JSON（云同步用）
  Map<String, dynamic> toJson() {
    return {
      'totalFocusMinutes': totalFocusMinutes,
      'todayFocusMinutes': todayFocusMinutes,
      'thisWeekFocusMinutes': thisWeekFocusMinutes,
      'todaySessions': todaySessions,
      'totalSessions': totalSessions,
      'avgEfficiency': avgEfficiency,
      'lastRecordTime': lastRecordTime?.toIso8601String(),
    };
  }

  StatisticsOverviewDTO copyWith({
    int? totalFocusMinutes,
    int? todayFocusMinutes,
    int? thisWeekFocusMinutes,
    int? todaySessions,
    int? totalSessions,
    double? avgEfficiency,
    DateTime? lastRecordTime,
  }) {
    return StatisticsOverviewDTO(
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      todayFocusMinutes: todayFocusMinutes ?? this.todayFocusMinutes,
      thisWeekFocusMinutes: thisWeekFocusMinutes ?? this.thisWeekFocusMinutes,
      todaySessions: todaySessions ?? this.todaySessions,
      totalSessions: totalSessions ?? this.totalSessions,
      avgEfficiency: avgEfficiency ?? this.avgEfficiency,
      lastRecordTime: lastRecordTime ?? this.lastRecordTime,
    );
  }

  @override
  List<Object?> get props => [
        totalFocusMinutes,
        todayFocusMinutes,
        thisWeekFocusMinutes,
        todaySessions,
        totalSessions,
        avgEfficiency,
        lastRecordTime,
      ];
}

/// 每日统计 DTO（图表用）
class DailyStatisticsDTO extends Equatable {
  final DateTime date;
  final int focusMinutes;
  final int sessions;
  final int completedSessions;
  final double? efficiency;

  const DailyStatisticsDTO({
    required this.date,
    required this.focusMinutes,
    required this.sessions,
    required this.completedSessions,
    this.efficiency,
  });

  /// 从 JSON 反序列化
  factory DailyStatisticsDTO.fromJson(Map<String, dynamic> json) {
    return DailyStatisticsDTO(
      date: DateTime.parse(json['date'] as String),
      focusMinutes: json['focusMinutes'] as int,
      sessions: json['sessions'] as int,
      completedSessions: json['completedSessions'] as int,
      efficiency: json['efficiency'] as double?,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'focusMinutes': focusMinutes,
      'sessions': sessions,
      'completedSessions': completedSessions,
      'efficiency': efficiency,
    };
  }

  DailyStatisticsDTO copyWith({
    DateTime? date,
    int? focusMinutes,
    int? sessions,
    int? completedSessions,
    double? efficiency,
  }) {
    return DailyStatisticsDTO(
      date: date ?? this.date,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      sessions: sessions ?? this.sessions,
      completedSessions: completedSessions ?? this.completedSessions,
      efficiency: efficiency ?? this.efficiency,
    );
  }

  @override
  List<Object?> get props => [
        date,
        focusMinutes,
        sessions,
        completedSessions,
        efficiency,
      ];
}

/// 任务完成率统计 DTO
class TaskCompletionStatsDTO extends Equatable {
  final int totalTasks; // 总任务数
  final int completedTasks; // 已完成任务数
  final int createdToday; // 今日创建
  final int completedToday; // 今日完成
  final Map<int, int> byImportance; // 按重要性分布
  final double completionRate; // 完成率

  const TaskCompletionStatsDTO({
    required this.totalTasks,
    required this.completedTasks,
    required this.createdToday,
    required this.completedToday,
    required this.byImportance,
    required this.completionRate,
  });

  /// 从 JSON 反序列化
  factory TaskCompletionStatsDTO.fromJson(Map<String, dynamic> json) {
    return TaskCompletionStatsDTO(
      totalTasks: json['totalTasks'] as int,
      completedTasks: json['completedTasks'] as int,
      createdToday: json['createdToday'] as int,
      completedToday: json['completedToday'] as int,
      byImportance: Map<int, int>.from(json['byImportance'] as Map),
      completionRate: (json['completionRate'] as num).toDouble(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'createdToday': createdToday,
      'completedToday': completedToday,
      'byImportance': byImportance,
      'completionRate': completionRate,
    };
  }

  TaskCompletionStatsDTO copyWith({
    int? totalTasks,
    int? completedTasks,
    int? createdToday,
    int? completedToday,
    Map<int, int>? byImportance,
    double? completionRate,
  }) {
    return TaskCompletionStatsDTO(
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      createdToday: createdToday ?? this.createdToday,
      completedToday: completedToday ?? this.completedToday,
      byImportance: byImportance ?? this.byImportance,
      completionRate: completionRate ?? this.completionRate,
    );
  }

  @override
  List<Object?> get props => [
        totalTasks,
        completedTasks,
        createdToday,
        completedToday,
        byImportance,
        completionRate,
      ];
}

/// 周趋势统计 DTO
class WeeklyTrendDTO extends Equatable {
  final List<DailyStatisticsDTO> dailyData;
  final int weekTotalMinutes;
  final double avgDailyMinutes;
  final double? efficiencyTrend; // 效率趋势
  final int bestDayMinutes; // 最佳日专注

  const WeeklyTrendDTO({
    required this.dailyData,
    required this.weekTotalMinutes,
    required this.avgDailyMinutes,
    this.efficiencyTrend,
    required this.bestDayMinutes,
  });

  /// 从 JSON 反序列化
  factory WeeklyTrendDTO.fromJson(Map<String, dynamic> json) {
    return WeeklyTrendDTO(
      dailyData: (json['dailyData'] as List)
          .map((e) => DailyStatisticsDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      weekTotalMinutes: json['weekTotalMinutes'] as int,
      avgDailyMinutes: (json['avgDailyMinutes'] as num).toDouble(),
      efficiencyTrend: json['efficiencyTrend'] as double?,
      bestDayMinutes: json['bestDayMinutes'] as int,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'dailyData': dailyData.map((e) => e.toJson()).toList(),
      'weekTotalMinutes': weekTotalMinutes,
      'avgDailyMinutes': avgDailyMinutes,
      'efficiencyTrend': efficiencyTrend,
      'bestDayMinutes': bestDayMinutes,
    };
  }

  WeeklyTrendDTO copyWith({
    List<DailyStatisticsDTO>? dailyData,
    int? weekTotalMinutes,
    double? avgDailyMinutes,
    double? efficiencyTrend,
    int? bestDayMinutes,
  }) {
    return WeeklyTrendDTO(
      dailyData: dailyData ?? this.dailyData,
      weekTotalMinutes: weekTotalMinutes ?? this.weekTotalMinutes,
      avgDailyMinutes: avgDailyMinutes ?? this.avgDailyMinutes,
      efficiencyTrend: efficiencyTrend ?? this.efficiencyTrend,
      bestDayMinutes: bestDayMinutes ?? this.bestDayMinutes,
    );
  }

  @override
  List<Object?> get props => [
        dailyData,
        weekTotalMinutes,
        avgDailyMinutes,
        efficiencyTrend,
        bestDayMinutes,
      ];
}

/// 任务专注统计 DTO
class TaskFocusStatsDTO extends Equatable {
  final String taskId;
  final String taskTitle;
  final int totalMinutes;
  final int sessions;
  final DateTime lastRecordTime;

  const TaskFocusStatsDTO({
    required this.taskId,
    required this.taskTitle,
    required this.totalMinutes,
    required this.sessions,
    required this.lastRecordTime,
  });

  /// 从 JSON 反序列化
  factory TaskFocusStatsDTO.fromJson(Map<String, dynamic> json) {
    return TaskFocusStatsDTO(
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String,
      totalMinutes: json['totalMinutes'] as int,
      sessions: json['sessions'] as int,
      lastRecordTime: DateTime.parse(json['lastRecordTime'] as String),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'totalMinutes': totalMinutes,
      'sessions': sessions,
      'lastRecordTime': lastRecordTime.toIso8601String(),
    };
  }

  TaskFocusStatsDTO copyWith({
    String? taskId,
    String? taskTitle,
    int? totalMinutes,
    int? sessions,
    DateTime? lastRecordTime,
  }) {
    return TaskFocusStatsDTO(
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      sessions: sessions ?? this.sessions,
      lastRecordTime: lastRecordTime ?? this.lastRecordTime,
    );
  }

  @override
  List<Object?> get props => [
        taskId,
        taskTitle,
        totalMinutes,
        sessions,
        lastRecordTime,
      ];
}

/// 任务完成趋势 DTO（用于展示每日创建/完成数量趋势）
class TaskCompletionTrendDTO extends Equatable {
  final DateTime date;
  final int created;
  final int completed;

  const TaskCompletionTrendDTO({
    required this.date,
    required this.created,
    required this.completed,
  });

  /// 从 JSON 反序列化
  factory TaskCompletionTrendDTO.fromJson(Map<String, dynamic> json) {
    return TaskCompletionTrendDTO(
      date: DateTime.parse(json['date'] as String),
      created: json['created'] as int,
      completed: json['completed'] as int,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'created': created,
      'completed': completed,
    };
  }

  TaskCompletionTrendDTO copyWith({
    DateTime? date,
    int? created,
    int? completed,
  }) {
    return TaskCompletionTrendDTO(
      date: date ?? this.date,
      created: created ?? this.created,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
        date,
        created,
        completed,
      ];
}
