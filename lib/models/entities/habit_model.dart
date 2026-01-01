import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// 习惯目标类型枚举
enum HabitTargetType { daily, weekly }

/// 习惯数据模型
/// 与 Drift 生成的 Habit 数据类区分
class HabitEntity {
  final String id;
  final String name;
  final String? description;
  final int targetType; // 0=每日, 1=每周
  final int targetValue;
  final String? color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const HabitEntity({
    required this.id,
    required this.name,
    this.description,
    required this.targetType,
    required this.targetValue,
    this.color,
    this.icon,
    required this.isActive,
    required this.createdAt,
    this.archivedAt,
  });

  /// 从数据库行转换
  factory HabitEntity.fromRow(Habit habit) {
    return HabitEntity(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      targetType: habit.targetType,
      targetValue: habit.targetValue,
      color: habit.color,
      icon: habit.icon,
      isActive: habit.isActive,
      createdAt: habit.createdAt,
      archivedAt: habit.archivedAt,
    );
  }

  /// 转换为 Insertable for Habit
  Insertable<Habit> toCompanion() {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      description: description != null ? Value(description!) : const Value.absent(),
      targetType: Value(targetType),
      targetValue: Value(targetValue),
      color: color != null ? Value(color!) : const Value.absent(),
      icon: icon != null ? Value(icon!) : const Value.absent(),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      archivedAt: archivedAt != null ? Value(archivedAt!) : const Value.absent(),
    );
  }

  /// 获取目标类型枚举
  HabitTargetType get targetTypeEnum {
    return targetType == 0 ? HabitTargetType.daily : HabitTargetType.weekly;
  }

  /// 判断是否为每日习惯
  bool get isDaily => targetType == 0;

  /// 判断是否为每周习惯
  bool get isWeekly => targetType == 1;

  /// 复制并修改属性
  HabitEntity copyWith({
    String? id,
    String? name,
    String? description,
    int? targetType,
    int? targetValue,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? archivedAt,
  }) {
    return HabitEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

/// 习惯统计信息
class HabitWithStats {
  final HabitEntity habit;
  final int totalCheckIns;
  final int currentStreak;
  final int? lastCheckInDaysAgo;
  final bool isCheckedInToday;

  const HabitWithStats({
    required this.habit,
    required this.totalCheckIns,
    required this.currentStreak,
    this.lastCheckInDaysAgo,
    required this.isCheckedInToday,
  });
}
