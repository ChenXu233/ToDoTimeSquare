import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/schema/habits.dart';
import '../entities/habit_model.dart';

part 'habit_repository.g.dart';

/// 习惯仓储
/// 提供习惯的 CRUD 操作和查询
@DriftAccessor(tables: [Habits])
class HabitRepository extends DatabaseAccessor<AppDatabase>
    with _$HabitRepositoryMixin {
  HabitRepository(super.db);

  // ========== 基础 CRUD ==========

  /// 获取所有习惯
  Future<List<HabitEntity>> getAllHabits() async {
    final query = select(habits)
      ..orderBy([
        (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(HabitEntity.fromRow).toList();
  }

  /// 获取活跃习惯
  Future<List<HabitEntity>> getActiveHabits() async {
    final query = select(habits)
      ..where((h) => h.isActive.equals(true))
      ..orderBy([
        (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(HabitEntity.fromRow).toList();
  }

  /// 获取已归档习惯
  Future<List<HabitEntity>> getArchivedHabits() async {
    final query = select(habits)
      ..where((h) => h.isActive.equals(false))
      ..orderBy([
        (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(HabitEntity.fromRow).toList();
  }

  /// 按 ID 获取习惯
  Future<HabitEntity?> getHabitById(String id) async {
    final query = select(habits)..where((h) => h.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? HabitEntity.fromRow(row) : null;
  }

  // ========== 插入操作 ==========

  /// 创建新习惯
  Future<void> createHabit(HabitEntity habit) async {
    final entity = habit.toCompanion();
    await into(habits).insert(entity);
  }

  // ========== 更新操作 ==========

  /// 更新习惯
  Future<bool> updateHabit(HabitEntity habit) async {
    final entity = habit.toCompanion();
    final result = await update(habits).replace(entity);
    return result;
  }

  /// 归档习惯
  Future<bool> archiveHabit(String id) async {
    final habit = await getHabitById(id);
    if (habit == null) return false;

    final updated = habit.copyWith(
      isActive: false,
      archivedAt: DateTime.now(),
    );
    return await updateHabit(updated);
  }

  /// 恢复习惯
  Future<bool> unarchiveHabit(String id) async {
    final habit = await getHabitById(id);
    if (habit == null) return false;

    final updated = habit.copyWith(
      isActive: true,
      archivedAt: null,
    );
    return await updateHabit(updated);
  }

  // ========== 删除操作 ==========

  /// 删除习惯
  Future<void> deleteHabit(String id) async {
    await (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  // ========== 统计查询 ==========

  /// 获取习惯总数
  Future<int> getTotalCount() async {
    final query = select(habits);
    final rows = await query.get();
    return rows.length;
  }

  /// 获取活跃习惯数
  Future<int> getActiveCount() async {
    final query = select(habits)..where((h) => h.isActive.equals(true));
    final rows = await query.get();
    return rows.length;
  }

  /// 检查名称是否已存在
  Future<bool> isNameExists(String name, {String? excludeId}) async {
    final query = select(habits)
      ..where((h) => h.name.equals(name));

    if (excludeId != null) {
      query.where((h) => h.id.equals(excludeId).not());
    }

    final rows = await query.get();
    return rows.isNotEmpty;
  }
}
