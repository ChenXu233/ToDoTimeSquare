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

  void addTodo(
    String title, {
    String? description,
    Duration? estimatedDuration,
    TodoImportance importance = TodoImportance.medium,
    DateTime? plannedStartTime,
  }) {
    _todos.add(
      Todo(
        id: DateTime.now().toString(),
        title: title,
        description: description,
        estimatedDuration: estimatedDuration,
        importance: importance,
        plannedStartTime: plannedStartTime,
      ),
    );
    _sortTodos();
    _saveTodos();
    notifyListeners();
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
    _todos.removeWhere((todo) => todo.id == id);
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
