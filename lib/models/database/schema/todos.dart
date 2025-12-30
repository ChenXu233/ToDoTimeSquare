import 'package:drift/drift.dart';

/// 任务重要性枚举
enum TodoImportance { low, medium, high }

/// 任务表定义
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().nullable()();
  IntColumn get estimatedDuration => integer().nullable()();
  IntColumn get importance => integer().withDefault(const Constant(1))();
  DateTimeColumn get plannedStartTime => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get parentId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  List<Set<Column>> get indexes => [
        {parentId},
        {isCompleted},
        {createdAt},
        {plannedStartTime},
      ];

  @override
  Set<Column> get primaryKey => {id};
}
