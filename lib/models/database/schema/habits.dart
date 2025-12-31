import 'package:drift/drift.dart';

/// 习惯目标类型枚举
enum HabitTargetType { daily, weekly }

/// 习惯表定义
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get targetType => integer().withDefault(const Constant(0))(); // 0=每日, 1=每周
  IntColumn get targetValue => integer().withDefault(const Constant(1))(); // 目标值
  TextColumn get color => text().nullable()(); // UI展示颜色 (hex)
  TextColumn get icon => text().nullable()(); // 图标标识
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  List<Set<Column>> get indexes => [
        {isActive},
        {createdAt},
      ];
}
