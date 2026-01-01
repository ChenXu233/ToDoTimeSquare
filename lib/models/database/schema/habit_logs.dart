import 'package:drift/drift.dart';

/// 习惯打卡记录表定义
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  DateTimeColumn get date => dateTime()(); // 打卡日期
  IntColumn get completedValue => integer().withDefault(const Constant(1))(); // 完成值
  TextColumn get notes => text().nullable()(); // 打卡备注
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  List<Set<Column>> get indexes => [
        {habitId},
        {date},
        {habitId, date}, // 便于查询某习惯的某日打卡
      ];
}
