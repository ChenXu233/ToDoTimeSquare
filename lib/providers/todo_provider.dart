import 'package:flutter/material.dart';
import '../models/database/database_initializer.dart';
import '../models/repositories/todo_repository.dart';
import '../models/models.dart';

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
    _todos.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });
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

    _todos.add(newTodo);
    _sortTodos();
    notifyListeners();

    // 保存到数据库
    _repository.createTask(newTodo);

    return newTodo.id;
  }

  List<TaskModel> getSubTasks(String parentId) {
    return _todos.where((todo) => todo.parentId == parentId).toList();
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
        updatedAt: DateTime.now(),
        completedAt: !_todos[index].isCompleted ? DateTime.now() : null,
      );
      _sortTodos();
      notifyListeners();

      // 更新数据库
      await _repository.updateTask(_todos[index]);
    }
  }

  Future<void> markTodoCompleted(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;
    if (_todos[index].isCompleted) {
      _sortTodos();
      notifyListeners();
      return;
    }
    _todos[index] = _todos[index].copyWith(
      isCompleted: true,
      updatedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
    await _repository.updateTask(_todos[index]);
    _sortTodos();
    notifyListeners();
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

  Future<void> moveTodo(String todoId, int newIndex) async {
    final currentIndex = _todos.indexWhere((todo) => todo.id == todoId);
    if (currentIndex == -1) return;

    final todo = _todos.removeAt(currentIndex);
    final adjustedIndex = newIndex.clamp(0, _todos.length);
    _todos.insert(adjustedIndex, todo);
    _sortTodos();
    notifyListeners();
  }

  Future<void> reorderTodos(List<String> orderedIds) async {
    final idSet = orderedIds.toSet();
    final reordered = <TaskModel>[];

    for (final id in orderedIds) {
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        reordered.add(_todos[index]);
      }
    }

    for (final todo in _todos) {
      if (!idSet.contains(todo.id)) {
        reordered.add(todo);
      }
    }

    _todos = reordered;
    _sortTodos();
    notifyListeners();
  }
}
