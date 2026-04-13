import 'package:drift/drift.dart';

/// 任务标签关联表（多对多关系）
@TableIndex(name: 'task_tag_relations_todo_id_idx', columns: {#todoId})
@TableIndex(name: 'task_tag_relations_tag_id_idx', columns: {#tagId})
class TaskTagRelations extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text()();
  TextColumn get tagId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
