import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// 习惯打卡记录数据模型
/// 与 Drift 生成的 HabitLog 数据类区分
class HabitLogEntity {
  final String id;
  final String habitId;
  final DateTime date;
  final int completedValue;
  final String? notes;
  final DateTime createdAt;

  const HabitLogEntity({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completedValue,
    this.notes,
    required this.createdAt,
  });

  /// 从数据库行转换
  factory HabitLogEntity.fromRow(HabitLog log) {
    return HabitLogEntity(
      id: log.id,
      habitId: log.habitId,
      date: log.date,
      completedValue: log.completedValue,
      notes: log.notes,
      createdAt: log.createdAt,
    );
  }

  /// 转换为 Insertable for HabitLog
  Insertable<HabitLog> toCompanion() {
    return HabitLogsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      completedValue: Value(completedValue),
      notes: notes != null ? Value(notes!) : const Value.absent(),
      createdAt: Value(createdAt),
    );
  }

  /// 获取日期字符串 (YYYY-MM-DD)
  String get dateString {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 复制并修改属性
  HabitLogEntity copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    int? completedValue,
    String? notes,
    DateTime? createdAt,
  }) {
    return HabitLogEntity(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completedValue: completedValue ?? this.completedValue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
