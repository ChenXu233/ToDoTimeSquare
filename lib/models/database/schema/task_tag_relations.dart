import 'package:drift/drift.dart';

/// 任务标签关联表（多对多关系）
class TaskTagRelations extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text()();
  TextColumn get tagId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get indexes => [
        {todoId},
        {tagId},
      ];
}
