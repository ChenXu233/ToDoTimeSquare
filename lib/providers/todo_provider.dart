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

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosString = prefs.getString('todos');
    if (todosString != null) {
      final List<dynamic> todosJson = jsonDecode(todosString);
      _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
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
    _saveTodos();
    notifyListeners();
  }

  void toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index].isCompleted = !_todos[index].isCompleted;
      _saveTodos();
      notifyListeners();
    }
  }

  void removeTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    _saveTodos();
    notifyListeners();
  }
}
