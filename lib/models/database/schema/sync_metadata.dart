import 'package:drift/drift.dart';

/// 同步元数据表
/// 用于追踪各实体的同步状态和变更时间
class SyncMetadataTable extends Table {
  TextColumn get entityType => text()(); // 'todo' | 'focus_record' | 'habit' | 'habit_log' | 'tag' | 'tag_relation'
  TextColumn get entityId => text()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))(); // 'synced' | 'pending' | 'conflict'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // 软删除标记

  @override
  Set<Column> get primaryKey => {entityType, entityId};

  List<Set<Column>> get indexes => [
        {syncStatus},
        {updatedAt},
        {entityType},
      ];
}
