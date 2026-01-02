import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/schema/task_tags.dart';
import '../database/schema/task_tag_relations.dart';
import '../entities/task_tag_model.dart';

part 'task_tag_repository.g.dart';

/// 标签仓储
/// 提供标签和关联的 CRUD 操作
@DriftAccessor(tables: [TaskTags, TaskTagRelations])
class TaskTagRepository extends DatabaseAccessor<AppDatabase>
    with _$TaskTagRepositoryMixin {
  TaskTagRepository(super.db);

  // ========== 标签基础 CRUD ==========

  /// 获取所有标签
  Future<List<TaskTagEntity>> getAllTags() async {
    final query = select(taskTags)
      ..orderBy([
        (t) => OrderingTerm(expression: t.type, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
      ]);
    final rows = await query.get();
    return rows.map(_rowToEntity).toList();
  }

  /// 按类型获取标签
  Future<List<TaskTagEntity>> getTagsByType(int type) async {
    final query = select(taskTags)
      ..where((t) => t.type.equals(type))
      ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);
    final rows = await query.get();
    return rows.map(_rowToEntity).toList();
  }

  /// 按 ID 获取标签
  Future<TaskTagEntity?> getTagById(String id) async {
    final query = select(taskTags)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToEntity(row) : null;
  }

  /// 获取用户标签
  Future<List<TaskTagEntity>> getTagsByUserId(String userId) async {
    final query = select(taskTags)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm(expression: t.type, mode: OrderingMode.asc)]);
    final rows = await query.get();
    return rows.map(_rowToEntity).toList();
  }

  /// 获取常用标签（按使用次数排序）
  Future<List<TaskTagEntity>> getFrequentlyUsedTags({int limit = 10}) async {
    final query = select(taskTags)
      ..orderBy([
        (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    final rows = await query.get();
    return rows.map(_rowToEntity).toList();
  }

  /// 创建标签
  Future<void> createTag(TaskTagEntity tag) async {
    await into(taskTags).insert(_entityToCompanion(tag));
  }

  /// 更新标签
  Future<bool> updateTag(TaskTagEntity tag) async {
    final now = DateTime.now();
    final updatedTag = tag.copyWith(updatedAt: now);
    final result = await update(taskTags).replace(_entityToCompanion(updatedTag));
    return result;
  }

  /// 删除标签
  Future<void> deleteTag(String id) async {
    // 先删除关联
    await deleteTaskTagRelationsByTagId(id);
    // 再删除标签
    await (delete(taskTags)..where((t) => t.id.equals(id))).go();
  }

  // ========== 关联管理 ==========

  /// 获取任务的标签关联
  Future<List<TaskTagRelationEntity>> getRelationsByTodoId(String todoId) async {
    final query = select(taskTagRelations)
      ..where((t) => t.todoId.equals(todoId));
    final rows = await query.get();
    return rows.map(_relationRowToEntity).toList();
  }

  /// 获取标签的所有关联
  Future<List<TaskTagRelationEntity>> getRelationsByTagId(String tagId) async {
    final query = select(taskTagRelations)
      ..where((t) => t.tagId.equals(tagId));
    final rows = await query.get();
    return rows.map(_relationRowToEntity).toList();
  }

  /// 获取任务的所有标签
  Future<List<TaskTagEntity>> getTagsForTask(String todoId) async {
    final relations = await getRelationsByTodoId(todoId);
    final tags = <TaskTagEntity>[];
    for (final relation in relations) {
      final tag = await getTagById(relation.tagId);
      if (tag != null) {
        tags.add(tag);
      }
    }
    return tags;
  }

  /// 为任务添加标签
  Future<void> addTagToTask(String todoId, String tagId) async {
    // 检查是否已存在关联
    final existing = await (select(taskTagRelations)
          ..where((t) => t.todoId.equals(todoId) & t.tagId.equals(tagId)))
        .getSingleOrNull();

    if (existing == null) {
      final relation = TaskTagRelationEntity(
        id: '${todoId}_${tagId}_${DateTime.now().millisecondsSinceEpoch}',
        todoId: todoId,
        tagId: tagId,
        createdAt: DateTime.now(),
      );
      await into(taskTagRelations).insert(_relationEntityToCompanion(relation));

      // 增加标签使用次数
      await _incrementTagUsage(tagId);
    }
  }

  /// 为任务移除标签
  Future<void> removeTagFromTask(String todoId, String tagId) async {
    await (delete(taskTagRelations)
          ..where((t) => t.todoId.equals(todoId) & t.tagId.equals(tagId)))
        .go();

    // 减少标签使用次数
    await _decrementTagUsage(tagId);
  }

  /// 设置任务的所有标签（覆盖）
  Future<void> setTagsForTask(String todoId, List<String> tagIds) async {
    // 删除现有关联
    (delete(taskTagRelations)
      ..where((t) => t.todoId.equals(todoId)))
        .go();

    // 创建新关联
    for (final tagId in tagIds) {
      await addTagToTask(todoId, tagId);
    }
  }

  /// 删除任务的关联
  Future<void> deleteTaskTagRelationsByTodoId(String todoId) async {
    // 先获取所有关联的 tagId
    final relations = await getRelationsByTodoId(todoId);
    for (final relation in relations) {
      await _decrementTagUsage(relation.tagId);
    }
    await (delete(taskTagRelations)..where((t) => t.todoId.equals(todoId))).go();
  }

  /// 删除标签的所有关联
  Future<void> deleteTaskTagRelationsByTagId(String tagId) async {
    await (delete(taskTagRelations)..where((t) => t.tagId.equals(tagId))).go();
  }

  // ========== 统计查询 ==========

  /// 获取标签总数
  Future<int> getTagCount() async {
    final query = select(taskTags);
    final rows = await query.get();
    return rows.length;
  }

  /// 按类型统计标签
  Future<int> getTagCountByType(int type) async {
    final query = select(taskTags)..where((t) => t.type.equals(type));
    final rows = await query.get();
    return rows.length;
  }

  /// 搜索标签
  Future<List<TaskTagEntity>> searchTags(String query) async {
    final searchQuery = select(taskTags)
      ..where((t) => t.name.like('%$query%'))
      ..orderBy([(t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc)]);
    final rows = await searchQuery.get();
    return rows.map(_rowToEntity).toList();
  }

  /// 获取有标签的任务数量
  Future<int> getTaggedTaskCount(String tagId) async {
    final query = select(taskTagRelations)
      ..where((t) => t.tagId.equals(tagId));
    final rows = await query.get();
    return rows.length;
  }

  // ========== 内部方法 ==========

  /// 将数据库行转换为实体
  TaskTagEntity _rowToEntity(TaskTag row) {
    return TaskTagEntity(
      id: row.id,
      userId: row.userId,
      name: row.name,
      color: row.color,
      type: TagType.values[row.type],
      icon: row.icon,
      isPreset: row.isPreset,
      usageCount: row.usageCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// 将关联表行转换为实体
  TaskTagRelationEntity _relationRowToEntity(TaskTagRelation row) {
    return TaskTagRelationEntity(
      id: row.id,
      todoId: row.todoId,
      tagId: row.tagId,
      createdAt: row.createdAt,
    );
  }

  /// 将实体转换为 Companion
  TaskTagsCompanion _entityToCompanion(TaskTagEntity entity) {
    return TaskTagsCompanion(
      id: Value(entity.id),
      userId: Value(entity.userId),
      name: Value(entity.name),
      color: Value(entity.color),
      type: Value(entity.type.index),
      icon: entity.icon != null ? Value(entity.icon!) : const Value.absent(),
      isPreset: Value(entity.isPreset),
      usageCount: Value(entity.usageCount),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  /// 将关联实体转换为 Companion
  TaskTagRelationsCompanion _relationEntityToCompanion(TaskTagRelationEntity entity) {
    return TaskTagRelationsCompanion(
      id: Value(entity.id),
      todoId: Value(entity.todoId),
      tagId: Value(entity.tagId),
      createdAt: Value(entity.createdAt),
    );
  }

  /// 增加标签使用次数
  Future<void> _incrementTagUsage(String tagId) async {
    final tag = await getTagById(tagId);
    if (tag != null) {
      await updateTag(tag.copyWith(usageCount: tag.usageCount + 1));
    }
  }

  /// 减少标签使用次数
  Future<void> _decrementTagUsage(String tagId) async {
    final tag = await getTagById(tagId);
    if (tag != null && tag.usageCount > 0) {
      await updateTag(tag.copyWith(usageCount: tag.usageCount - 1));
    }
  }
}
