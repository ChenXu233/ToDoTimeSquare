import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];

  TodoProvider() {
    _loadTodos();
  }

  List<Todo> get todos => _todos;

  void _sortTodos() {
    _todos.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosString = prefs.getString('todos');
    if (todosString != null) {
      final List<dynamic> todosJson = jsonDecode(todosString);
      _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
      _sortTodos();
      notifyListeners();
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String todosString = jsonEncode(
      _todos.map((todo) => todo.toJson()).toList(),
    );
    await prefs.setString('todos', todosString);
  }

  String addTodo(
    String title, {
    String? description,
    Duration? estimatedDuration,
    TodoImportance importance = TodoImportance.medium,
    DateTime? plannedStartTime,
    String? parentId,
  }) {
    final newTodo = Todo(
      id: DateTime.now().toString(),
      title: title,
      description: description,
      estimatedDuration: estimatedDuration,
      importance: importance,
      plannedStartTime: plannedStartTime,
      parentId: parentId,
    );
    _todos.add(newTodo);
    _sortTodos();
    _saveTodos();
    notifyListeners();
    return newTodo.id;
  }

  List<Todo> getSubTasks(String parentId) {
    return _todos.where((todo) => todo.parentId == parentId).toList();
  }

  void toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index].isCompleted = !_todos[index].isCompleted;
      _saveTodos();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      _sortTodos();
      notifyListeners();
    }
  }

  void removeTodo(String id) {
    final idsToRemove = <String>{id};

    // Find all descendants
    void addDescendants(String parentId) {
      final children = _todos.where((t) => t.parentId == parentId);
      for (var child in children) {
        idsToRemove.add(child.id);
        addDescendants(child.id);
      }
    }

    addDescendants(id);

    _todos.removeWhere((todo) => idsToRemove.contains(todo.id));
    _saveTodos();
    notifyListeners();
  }

  void updateTodo(Todo updatedTodo) {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index != -1) {
      _todos[index] = updatedTodo;
      _sortTodos();
      _saveTodos();
      notifyListeners();
    }
  }
}
