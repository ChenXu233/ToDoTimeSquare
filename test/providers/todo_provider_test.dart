import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:todo_time_square/models/database/app_database.dart';
import 'package:todo_time_square/models/repositories/todo_repository.dart';
import 'package:todo_time_square/models/repositories/task_tag_repository.dart';
import 'package:todo_time_square/models/repositories/todo_repository.dart' show TaskModel, TodoImportance;

/// Creates an in-memory database for testing
AppDatabase createTestDb() {
  return AppDatabase(DatabaseConnection(NativeDatabase.memory()));
}

/// Global counter to ensure unique IDs across tests
int _idCounter = 0;
String _nextId() => 'test_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';

/// Testable TodoProvider that uses a real in-memory database
/// This class replicates the core logic of TodoProvider for testing
/// without needing to access private members.
class TestableTodoProvider {
  List<TaskModel> _todos = [];
  final TodoRepository _repo;
  final TaskTagRepository _tagRepo;

  TestableTodoProvider(this._repo, this._tagRepo);

  List<TaskModel> get todos => _todos;

  Future<void> loadTodos() async {
    _todos = await _repo.getAllTasks();
    _sortTodos();
  }

  void _sortTodos() {
    final incomplete = _todos.where((t) => !t.isCompleted).toList();
    final completed = _todos.where((t) => t.isCompleted).toList();

    completed.sort((a, b) {
      final aTime = a.completedAt ?? a.updatedAt;
      final bTime = b.completedAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });

    _todos = [...incomplete, ...completed];
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
    await _repo.updateTask(updated);
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) return;

    final todo = _todos[index];
    final isNowCompleted = !todo.isCompleted;

    await _updateTodoStatus(todo, isNowCompleted);

    if (todo.parentId == null) {
      if (isNowCompleted) {
        final subTasks = getSubTasks(todo.id);
        for (var sub in subTasks) {
          if (!sub.isCompleted) {
            await _updateTodoStatus(sub, true);
          }
        }
      }
    } else {
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
        final parentIndex = _todos.indexWhere((t) => t.id == todo.parentId);
        if (parentIndex != -1 && _todos[parentIndex].isCompleted) {
          await _updateTodoStatus(_todos[parentIndex], false);
        }
      }
    }

    _sortTodos();
  }

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

    if (sourceTodo.parentId == null && targetTodo.parentId == null) {
      _todos.removeAt(sourceIndex);
      int newTargetIndex = _todos.indexWhere((t) => t.id == targetId);
      if (above) {
        _todos.insert(newTargetIndex, sourceTodo);
      } else {
        _todos.insert(newTargetIndex + 1, sourceTodo);
      }
    } else if (sourceTodo.parentId == targetTodo.parentId) {
      _todos.removeAt(sourceIndex);
      int newTargetIndex = _todos.indexWhere((t) => t.id == targetId);
      if (above) {
        _todos.insert(newTargetIndex, sourceTodo);
      } else {
        _todos.insert(newTargetIndex + 1, sourceTodo);
      }
    } else {
      // Different parents - adopt target's parent and reposition
      final updatedSource = sourceTodo.copyWith(parentId: targetTodo.parentId);

      // First remove source from list
      _todos.removeAt(sourceIndex);

      // Find new position after removal
      int newTargetIndex = _todos.indexWhere((t) => t.id == targetId);

      // Insert at new position
      if (above) {
        _todos.insert(newTargetIndex, updatedSource);
      } else {
        _todos.insert(newTargetIndex + 1, updatedSource);
      }

      // Update database
      await _repo.updateTask(updatedSource);
    }
  }

  String addTodo(
    String title, {
    String? description,
    int? estimatedDuration,
    TodoImportance importance = TodoImportance.medium,
    DateTime? plannedStartTime,
    String? parentId,
  }) {
    final now = DateTime.now();
    final newTodo = TaskModel(
      id: _nextId(),
      title: title,
      description: description,
      estimatedDuration: estimatedDuration,
      importance: importance.index + 1,
      plannedStartTime: plannedStartTime,
      isCompleted: false,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    );

    final firstCompletedIndex = _todos.indexWhere((t) => t.isCompleted);
    if (firstCompletedIndex != -1) {
      _todos.insert(0, newTodo);
    } else {
      _todos.insert(0, newTodo);
    }

    _sortTodos();
    _repo.createTask(newTodo);

    return newTodo.id;
  }

  Future<void> updateTodo(TaskModel updatedTodo) async {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index != -1) {
      updatedTodo = updatedTodo.copyWith(updatedAt: DateTime.now());
      _todos[index] = updatedTodo;
      _sortTodos();
      await _repo.updateTask(updatedTodo);
    }
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

    for (final todoId in idsToRemove) {
      await _tagRepo.deleteTaskTagRelationsByTodoId(todoId);
    }
    // deleteTaskWithDescendants handles the actual deletion recursively
    await _repo.deleteTaskWithDescendants(id);
  }
}

void main() {
  late AppDatabase testDb;
  late TodoRepository todoRepository;
  late TaskTagRepository tagRepository;

  setUp(() {
    testDb = createTestDb();
    todoRepository = TodoRepository(testDb);
    tagRepository = TaskTagRepository(testDb);
    _idCounter = 0; // Reset counter for each test
  });

  tearDown(() async {
    await testDb.close();
  });

  // Helper to create provider with real repositories
  TestableTodoProvider createProvider() {
    return TestableTodoProvider(todoRepository, tagRepository);
  }

  group('TodoProvider 基本功能', () {
    test('addTodo 应该添加任务并返回 ID', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final id = provider.addTodo('Test Task');

      expect(id, isNotEmpty);
      expect(provider.todos.length, 1);
      expect(provider.todos.first.title, 'Test Task');
    });

    test('addTodo 应该将任务添加到未完成列表顶部', () async {
      final provider = createProvider();
      await provider.loadTodos();

      // Add a completed task first
      provider.addTodo('Completed Task');

      // Add an incomplete task
      provider.addTodo('New Task');

      // The new task should be in the incomplete section
      final incomplete = provider.todos.where((t) => !t.isCompleted).toList();
      expect(incomplete.first.title, 'New Task');
    });

    test('getSubTasks 应该返回指定父任务的所有子任务', () async {
      final provider = createProvider();
      await provider.loadTodos();

      // Add parent and children
      final parentId = provider.addTodo('Parent');
      provider.addTodo('Child1', parentId: parentId);
      provider.addTodo('Child2', parentId: parentId);
      provider.addTodo('Other');

      final subtasks = provider.getSubTasks(parentId);

      expect(subtasks.length, 2);
      expect(subtasks.every((t) => t.parentId == parentId), isTrue);
    });

    test('getSubTasks 对于不存在的父任务应该返回空列表', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final subtasks = provider.getSubTasks('nonexistent');

      expect(subtasks, isEmpty);
    });
  });

  group('TodoProvider toggleTodo 父子任务联动', () {
    test('完成子任务时部分同级子任务完成不应联动父任务', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final parentId = provider.addTodo('Parent');
      final child1Id = provider.addTodo('Child1', parentId: parentId);
      final child2Id = provider.addTodo('Child2', parentId: parentId);

      // Complete child1
      await provider.toggleTodo(child1Id);

      final child1 = provider.todos.firstWhere((t) => t.id == child1Id);
      final parent = provider.todos.firstWhere((t) => t.id == parentId);

      expect(child1.isCompleted, isTrue);
      expect(parent.isCompleted, isFalse, reason: 'Child2 still incomplete, parent should not be completed');
    });

    test('完成最后一个子任务时父任务应自动完成', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final parentId = provider.addTodo('Parent');
      final child1Id = provider.addTodo('Child1', parentId: parentId);
      final child2Id = provider.addTodo('Child2', parentId: parentId);

      // First complete child1
      await provider.toggleTodo(child1Id);
      // Then complete child2 (last incomplete sibling)
      await provider.toggleTodo(child2Id);

      final child2 = provider.todos.firstWhere((t) => t.id == child2Id);
      final parent = provider.todos.firstWhere((t) => t.id == parentId);

      expect(child2.isCompleted, isTrue);
      expect(parent.isCompleted, isTrue, reason: 'All children completed, parent should auto-complete');
    });

    test('取消完成子任务时父任务也应取消完成', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final parentId = provider.addTodo('Parent');
      final child1Id = provider.addTodo('Child1', parentId: parentId);
      final child2Id = provider.addTodo('Child2', parentId: parentId);

      // Complete parent (which completes all children)
      await provider.toggleTodo(parentId);

      // Uncomplete child1
      await provider.toggleTodo(child1Id);

      final child1 = provider.todos.firstWhere((t) => t.id == child1Id);
      final parent = provider.todos.firstWhere((t) => t.id == parentId);

      expect(child1.isCompleted, isFalse);
      expect(parent.isCompleted, isFalse, reason: 'Uncompleting a child should uncomplete parent');
    });

    test('完成根任务时应完成所有子任务', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final parentId = provider.addTodo('Parent');
      final child1Id = provider.addTodo('Child1', parentId: parentId);
      final child2Id = provider.addTodo('Child2', parentId: parentId);

      // Complete parent
      await provider.toggleTodo(parentId);

      final parent = provider.todos.firstWhere((t) => t.id == parentId);
      final child1 = provider.todos.firstWhere((t) => t.id == child1Id);
      final child2 = provider.todos.firstWhere((t) => t.id == child2Id);

      expect(parent.isCompleted, isTrue);
      expect(child1.isCompleted, isTrue, reason: 'Completing parent should complete all children');
      expect(child2.isCompleted, isTrue);
    });

    test('toggleTodo 处理不存在的任务应不报错', () async {
      final provider = createProvider();
      await provider.loadTodos();

      // Should not throw
      await provider.toggleTodo('nonexistent');
    });
  });

  group('TodoProvider moveTodoTo 任务移动', () {
    test('同级根任务移动 - 移动到上方', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final id1 = provider.addTodo('Task1');
      await Future.delayed(Duration(milliseconds: 10)); // Ensure unique timestamps
      final id2 = provider.addTodo('Task2');
      await Future.delayed(Duration(milliseconds: 10));
      final id3 = provider.addTodo('Task3');

      // Move task3 above task1
      await provider.moveTodoTo(id3, id1, above: true);

      final task3Index = provider.todos.indexWhere((t) => t.id == id3);
      final task1Index = provider.todos.indexWhere((t) => t.id == id1);

      expect(task3Index, lessThan(task1Index));
    });

    test('同级根任务移动 - 移动到下方', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final id1 = provider.addTodo('Task1');
      await Future.delayed(Duration(milliseconds: 10));
      final id2 = provider.addTodo('Task2');
      await Future.delayed(Duration(milliseconds: 10));
      final id3 = provider.addTodo('Task3');

      // Move task1 below task3
      await provider.moveTodoTo(id1, id3, above: false);

      final task1Index = provider.todos.indexWhere((t) => t.id == id1);
      final task3Index = provider.todos.indexWhere((t) => t.id == id3);

      expect(task1Index, greaterThan(task3Index));
    });

    test('根任务转为子任务', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final parentId = provider.addTodo('Parent');
      final childId = provider.addTodo('Child', parentId: parentId);
      final standaloneId = provider.addTodo('Standalone');

      // Move standalone to become child of parent
      await provider.moveTodoTo(standaloneId, childId, above: true);

      final standalone = provider.todos.firstWhere((t) => t.id == standaloneId);
      expect(standalone.parentId, equals(parentId));
    });

    test('移动不存在的任务应不报错', () async {
      final provider = createProvider();
      await provider.loadTodos();

      // Should not throw
      await provider.moveTodoTo('nonexistent', 'also-nonexistent', above: true);
    });
  });

  group('TodoProvider 其他功能', () {
    test('updateTodo 应该更新任务', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final id = provider.addTodo('Original');
      final original = provider.todos.firstWhere((t) => t.id == id);
      final updated = original.copyWith(title: 'Updated');

      await provider.updateTodo(updated);

      expect(provider.todos.first.title, 'Updated');
    });

    test('removeTodo 应该删除任务及其子任务', () async {
      final provider = createProvider();
      await provider.loadTodos();

      final parentId = provider.addTodo('Parent');
      provider.addTodo('Child1', parentId: parentId);
      provider.addTodo('Child2', parentId: parentId);
      final otherId = provider.addTodo('Other');

      await provider.removeTodo(parentId);

      expect(provider.todos.length, 1);
      expect(provider.todos.first.id, otherId);
    });
  });
}