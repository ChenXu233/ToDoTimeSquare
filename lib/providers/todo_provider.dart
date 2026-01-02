import 'package:flutter/material.dart';
import '../models/database/database_initializer.dart';
import '../models/repositories/todo_repository.dart';

class TodoProvider extends ChangeNotifier {
  List<TaskModel> _todos = [];
  late final TodoRepository _repository;

  List<TaskModel> get todos => _todos;

  TodoProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final db = DatabaseInitializer().database;
    _repository = TodoRepository(db);
    await _loadTodos();
  }

  void _sortTodos() {
    final incomplete = _todos.where((t) => !t.isCompleted).toList();
    final completed = _todos.where((t) => t.isCompleted).toList();

    // Sort completed: newest completed first
    completed.sort((a, b) {
      final aTime = a.completedAt ?? a.updatedAt;
      final bTime = b.completedAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });

    // Incomplete: preserve order (manual sorting)
    // If just loaded, they are sorted by createdAt desc (from repository)

    _todos = [...incomplete, ...completed];
  }

  Future<void> _loadTodos() async {
    _todos = await _repository.getAllTasks();
    _sortTodos();
    notifyListeners();
  }

  String addTodo(
    String title, {
    String? description,
    int? estimatedDuration, // 分钟
    TodoImportance importance = TodoImportance.medium,
    DateTime? plannedStartTime,
    String? parentId,
  }) {
    final now = DateTime.now();
    final newTodo = TaskModel(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      estimatedDuration: estimatedDuration,
      importance: importance.index + 1, // enum → int
      plannedStartTime: plannedStartTime,
      isCompleted: false,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    );

    // Insert at top of incomplete tasks
    final firstCompletedIndex = _todos.indexWhere((t) => t.isCompleted);
    if (firstCompletedIndex != -1) {
      _todos.insert(0, newTodo);
    } else {
      _todos.insert(0, newTodo);
    }
    
    _sortTodos();
    notifyListeners();

    // 保存到数据库
    _repository.createTask(newTodo);

    return newTodo.id;
  }

  List<TaskModel> getSubTasks(String parentId) {
    return _todos.where((todo) => todo.parentId == parentId).toList();
  }

  Future<void> _updateTodoStatus(TaskModel todo, bool isCompleted) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;

    final updated = todo.copyWith(
      isCompleted: isCompleted,
      updatedAt: DateTime.now(),
      completedAt: isCompleted ? DateTime.now() : null,
    );

    _todos[index] = updated;
    await _repository.updateTask(updated);
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;

    final todo = _todos[index];
    final isNowCompleted = !todo.isCompleted;

    // Update the task itself
    await _updateTodoStatus(todo, isNowCompleted);

    // Logic for Parent/Child
    if (todo.parentId == null) {
      // It's a root task.
      // If completed -> Complete all subtasks
      if (isNowCompleted) {
        final subTasks = getSubTasks(todo.id);
        for (var sub in subTasks) {
          if (!sub.isCompleted) {
            await _updateTodoStatus(sub, true);
          }
        }
      }
    } else {
      // It's a subtask.
      // If completed -> Check if all siblings are completed. If so, complete parent.
      if (isNowCompleted) {
        final siblings = getSubTasks(todo.parentId!);
        final allCompleted = siblings.every((t) => t.isCompleted);
        if (allCompleted) {
          final parentIndex = _todos.indexWhere((t) => t.id == todo.parentId);
          if (parentIndex != -1) {
            await _updateTodoStatus(_todos[parentIndex], true);
          }
        }
      } else {
        // If uncompleted -> Uncomplete parent if it was completed
        final parentIndex = _todos.indexWhere((t) => t.id == todo.parentId);
        if (parentIndex != -1 && _todos[parentIndex].isCompleted) {
          await _updateTodoStatus(_todos[parentIndex], false);
        }
      }
    }

    _sortTodos();
    notifyListeners();
  }

  Future<void> markTodoCompleted(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    if (_todos[index].isCompleted) {
      _sortTodos();
      notifyListeners();
      return;
    }
    await toggleTodo(id);
  }

  Future<void> removeTodo(String id) async {
    final idsToRemove = <String>{id};

    void addDescendants(String parentId) {
      final children = _todos.where((t) => t.parentId == parentId);
      for (var child in children) {
        idsToRemove.add(child.id);
        addDescendants(child.id);
      }
    }

    addDescendants(id);

    _todos.removeWhere((todo) => idsToRemove.contains(todo.id));
    _sortTodos();
    notifyListeners();

    for (final todoId in idsToRemove) {
      await _repository.deleteTaskWithDescendants(todoId);
    }
  }

  Future<void> updateTodo(TaskModel updatedTodo) async {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index != -1) {
      updatedTodo = updatedTodo.copyWith(updatedAt: DateTime.now());
      _todos[index] = updatedTodo;
      _sortTodos();
      notifyListeners();

      await _repository.updateTask(updatedTodo);
    }
  }

  // Move todo to a specific position relative to another todo
  Future<void> moveTodoTo(
    String sourceId,
    String targetId, {
    required bool above,
  }) async {
    final sourceIndex = _todos.indexWhere((t) => t.id == sourceId);
    final targetIndex = _todos.indexWhere((t) => t.id == targetId);

    if (sourceIndex == -1 || targetIndex == -1) return;

    final sourceTodo = _todos[sourceIndex];
    final targetTodo = _todos[targetIndex];

    // Case 1: Both are root tasks
    if (sourceTodo.parentId == null && targetTodo.parentId == null) {
      _todos.removeAt(sourceIndex);
      // Re-calculate target index because removal might shift it
      int newTargetIndex = _todos.indexWhere((t) => t.id == targetId);
      if (above) {
        _todos.insert(newTargetIndex, sourceTodo);
      } else {
        _todos.insert(newTargetIndex + 1, sourceTodo);
      }
    }
    // Case 2: Both are subtasks of same parent
    else if (sourceTodo.parentId == targetTodo.parentId) {
      _todos.removeAt(sourceIndex);
      int newTargetIndex = _todos.indexWhere((t) => t.id == targetId);
      if (above) {
        _todos.insert(newTargetIndex, sourceTodo);
      } else {
        _todos.insert(newTargetIndex + 1, sourceTodo);
      }
    }
    // Case 3: Different parents or one is root and one is sub
    else {
      // Adopt target's parent
      final updatedSource = sourceTodo.copyWith(parentId: targetTodo.parentId);
      await _repository.updateTask(updatedSource); // Update DB

      final newSourceIndex = _todos.indexWhere((t) => t.id == sourceId);
      if (newSourceIndex != -1) {
        _todos[newSourceIndex] = updatedSource; // Update in place first
        _todos.removeAt(newSourceIndex);
        
        int newTargetIndex = _todos.indexWhere((t) => t.id == targetId);
        if (above) {
          _todos.insert(newTargetIndex, updatedSource);
        } else {
          _todos.insert(newTargetIndex + 1, updatedSource);
        }
      }
    }

    notifyListeners();
  }

  Future<void> convertToSubtask(String childId, String parentId) async {
    final childIndex = _todos.indexWhere((t) => t.id == childId);
    final parentIndex = _todos.indexWhere((t) => t.id == parentId);

    if (childIndex == -1 || parentIndex == -1) return;

    final child = _todos[childIndex];
    final parent = _todos[parentIndex];

    String? newParentId = parentId;
    if (parent.parentId != null) {
      newParentId = parent.parentId;
    }

    if (child.id == newParentId) return;

    final updatedChild = child.copyWith(parentId: newParentId);

    // Update in memory
    _todos[childIndex] = updatedChild;

    await _repository.updateTask(updatedChild);
    notifyListeners();
  }

  Future<void> detachFromParent(String childId) async {
    final childIndex = _todos.indexWhere((t) => t.id == childId);
    if (childIndex == -1) return;

    final child = _todos[childIndex];
    if (child.parentId == null) return;

    // Manually construct to set parentId to null
    final newChild = TaskModel(
      id: child.id,
      title: child.title,
      description: child.description,
      estimatedDuration: child.estimatedDuration,
      importance: child.importance,
      plannedStartTime: child.plannedStartTime,
      isCompleted: child.isCompleted,
      parentId: null,
      createdAt: child.createdAt,
      updatedAt: DateTime.now(),
      completedAt: child.completedAt,
    );

    _todos[childIndex] = newChild;
    await _repository.updateTask(newChild);
    notifyListeners();
  }
}
