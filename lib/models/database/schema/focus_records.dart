import 'package:drift/drift.dart';

/// 专注记录表定义
class FocusRecords extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().nullable()();
  TextColumn get taskTitle => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  IntColumn get durationSeconds => integer()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get interruptionCount => integer().withDefault(const Constant(0))();
  RealColumn get efficiencyScore => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  List<Set<Column>> get indexes => [
        {taskId},
        {startTime},
        {createdAt},
      ];
}
