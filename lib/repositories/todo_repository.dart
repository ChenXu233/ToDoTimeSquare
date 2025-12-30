import 'package:drift/drift.dart';
import '/database/app_database.dart';
import '/database/schema/todos.dart';

part 'todo_repository.g.dart';

/// 任务数据模型
/// 与现有的 Todo Model 保持兼容
class TaskModel {
  final String id;
  final String title;
  final String? description;
  final int? estimatedDuration; // 秒
  final int importance; // 0=low, 1=medium, 2=high
  final DateTime? plannedStartTime;
  final bool isCompleted;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.estimatedDuration,
    required this.importance,
    this.plannedStartTime,
    required this.isCompleted,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// 从数据库行转换
  factory TaskModel.fromRow(Todo todo) {
    return TaskModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      estimatedDuration: todo.estimatedDuration,
      importance: todo.importance,
      plannedStartTime: todo.plannedStartTime,
      isCompleted: todo.isCompleted,
      parentId: todo.parentId,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      completedAt: todo.completedAt,
    );
  }

  /// 转换为 Insertable
  Insertable<Todo> toCompanion() {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      description: description != null ? Value(description!) : const Value.absent(),
      estimatedDuration: estimatedDuration != null ? Value(estimatedDuration!) : const Value.absent(),
      importance: Value(importance),
      plannedStartTime: plannedStartTime != null ? Value(plannedStartTime!) : const Value.absent(),
      isCompleted: Value(isCompleted),
      parentId: parentId != null ? Value(parentId!) : const Value.absent(),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt != null ? Value(completedAt!) : const Value.absent(),
    );
  }
}

/// 任务仓储
/// 提供任务的 CRUD 操作和统计查询
@DriftAccessor(tables: [Todos])
class TodoRepository extends DatabaseAccessor<AppDatabase> with _$TodoRepositoryMixin {
  TodoRepository(super.db);

  // ========== 基础 CRUD ==========

  /// 获取所有任务
  Future<List<TaskModel>> getAllTasks() async {
    final query = select(todos)
      ..orderBy([
        (t) => OrderingTerm(
              expression: t.isCompleted,
              mode: OrderingMode.asc,
            ),
        (t) => OrderingTerm(
              expression: t.createdAt,
              mode: OrderingMode.desc,
            ),
      ]);
    final rows = await query.get();
    return rows.map(TaskModel.fromRow).toList();
  }

  /// 获取未完成任务
  Future<List<TaskModel>> getIncompleteTasks() async {
    final query = select(todos)
      ..where((t) => t.isCompleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    final rows = await query.get();
    return rows.map(TaskModel.fromRow).toList();
  }

  /// 获取已完成任务
  Future<List<TaskModel>> getCompletedTasks() async {
    final query = select(todos)
      ..where((t) => t.isCompleted.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc)]);
    final rows = await query.get();
    return rows.map(TaskModel.fromRow).toList();
  }

  /// 按 ID 获取任务
  Future<TaskModel?> getTaskById(String id) async {
    final query = select(todos)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? TaskModel.fromRow(row) : null;
  }

  /// 获取子任务
  Future<List<TaskModel>> getSubTasks(String parentId) async {
    final query = select(todos)
      ..where((t) => t.parentId.equals(parentId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    final rows = await query.get();
    return rows.map(TaskModel.fromRow).toList();
  }

  /// 获取顶级任务（无父任务）
  Future<List<TaskModel>> getRootTasks() async {
    final query = select(todos)
      ..where((t) => t.parentId.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(TaskModel.fromRow).toList();
  }

  // ========== 插入操作 ==========

  /// 创建新任务
  Future<void> createTask(TaskModel task) async {
    final entity = task.toCompanion();
    await into(todos).insert(entity);
  }

  // ========== 更新操作 ==========

  /// 更新任务
  Future<bool> updateTask(TaskModel task) async {
    final entity = task.toCompanion();
    final result = await update(todos).replace(entity);
    return result;
  }

  /// 切换任务完成状态
  Future<bool> toggleTaskCompletion(String id) async {
    final task = await getTaskById(id);
    if (task == null) return false;

    final now = DateTime.now();
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: now,
      completedAt: !task.isCompleted ? now : null,
    );

    return await updateTask(updatedTask);
  }

  /// 标记任务完成（包含子任务）
  Future<void> markTaskCompletedWithDescendants(String id) async {
    final task = await getTaskById(id);
    if (task == null || task.isCompleted) return;

    final now = DateTime.now();
    final updatedTask = task.copyWith(
      isCompleted: true,
      updatedAt: now,
      completedAt: now,
    );
    await updateTask(updatedTask);

    // 递归完成子任务
    final subTasks = await getSubTasks(id);
    for (final subTask in subTasks) {
      await markTaskCompletedWithDescendants(subTask.id);
    }
  }

  // ========== 删除操作 ==========

  /// 删除任务及其子任务
  Future<void> deleteTaskWithDescendants(String id) async {
    // 先删除所有子任务
    final subTasks = await getSubTasks(id);
    for (final subTask in subTasks) {
      await deleteTaskWithDescendants(subTask.id);
    }

    // 再删除当前任务
    await (delete(todos)..where((t) => t.id.equals(id))).go();
  }

  // ========== 统计查询 ==========

  /// 获取任务总数
  Future<int> getTotalCount() async {
    final query = select(todos);
    final rows = await query.get();
    return rows.length;
  }

  /// 获取已完成任务数
  Future<int> getCompletedCount() async {
    final query = select(todos)..where((t) => t.isCompleted.equals(true));
    final rows = await query.get();
    return rows.length;
  }

  /// 获取未完成任务数
  Future<int> getIncompleteCount() async {
    final query = select(todos)..where((t) => t.isCompleted.equals(false));
    final rows = await query.get();
    return rows.length;
  }

  /// 获取今日完成任务数
  Future<int> getTodayCompletedCount() async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final query = select(todos)
      ..where((t) => t.completedAt.isNotNull() & t.completedAt.isBiggerThanValue(today));
    final rows = await query.get();
    return rows.length;
  }

  /// 获取本周完成任务数
  Future<int> getThisWeekCompletedCount() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final query = select(todos)
      ..where((t) => t.completedAt.isNotNull() & t.completedAt.isBiggerThanValue(startOfWeek));
    final rows = await query.get();
    return rows.length;
  }

  // ========== 搜索 ==========

  /// 搜索任务
  Future<List<TaskModel>> searchTasks(String query) async {
    final searchQuery = select(todos)
      ..where((t) => t.title.like('%$query%') | (t.description.isNotNull() & t.description.like('%$query%')))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);

    final rows = await searchQuery.get();
    return rows.map(TaskModel.fromRow).toList();
  }

  /// 获取最近 N 条任务
  Future<List<TaskModel>> getRecentTasks(int limit) async {
    final query = select(todos)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(TaskModel.fromRow).toList();
  }
}

/// TaskModel 扩展
extension TaskModelExtension on TaskModel {
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    int? estimatedDuration,
    int? importance,
    DateTime? plannedStartTime,
    bool? isCompleted,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      importance: importance ?? this.importance,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      isCompleted: isCompleted ?? this.isCompleted,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
