import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_time_square/models/repositories/todo_repository.dart';
import 'package:todo_time_square/models/database/app_database.dart';

void main() {
  group('TaskModel', () {
    late TaskModel model;
    late DateTime now;

    setUp(() {
      now = DateTime(2024, 1, 15, 10, 30);
      model = TaskModel(
        id: 'task-1',
        title: 'Complete project',
        description: 'Finish the Flutter project',
        estimatedDuration: 3600,
        importance: 1,
        plannedStartTime: DateTime(2024, 1, 15, 14, 0),
        isCompleted: false,
        parentId: null,
        createdAt: now,
        updatedAt: now,
        completedAt: null,
      );
    });

    group('copyWith', () {
      test('should copy id only', () {
        final copied = model.copyWith(id: 'task-2');
        expect(copied.id, 'task-2');
        expect(copied.title, model.title);
        expect(copied.description, model.description);
        expect(copied.estimatedDuration, model.estimatedDuration);
        expect(copied.importance, model.importance);
        expect(copied.plannedStartTime, model.plannedStartTime);
        expect(copied.isCompleted, model.isCompleted);
        expect(copied.parentId, model.parentId);
        expect(copied.createdAt, model.createdAt);
        expect(copied.updatedAt, model.updatedAt);
        expect(copied.completedAt, model.completedAt);
      });

      test('should copy title only', () {
        final copied = model.copyWith(title: 'New Title');
        expect(copied.title, 'New Title');
        expect(copied.id, model.id);
      });

      test('should copy description only', () {
        final copied = model.copyWith(description: 'New description');
        expect(copied.description, 'New description');
        expect(copied.id, model.id);
      });

      test('should copy estimatedDuration only', () {
        final copied = model.copyWith(estimatedDuration: 7200);
        expect(copied.estimatedDuration, 7200);
        expect(copied.id, model.id);
      });

      test('should copy importance only', () {
        final copied = model.copyWith(importance: 2);
        expect(copied.importance, 2);
        expect(copied.id, model.id);
      });

      test('should copy plannedStartTime only', () {
        final newTime = DateTime(2024, 1, 20, 9, 0);
        final copied = model.copyWith(plannedStartTime: newTime);
        expect(copied.plannedStartTime, newTime);
        expect(copied.id, model.id);
      });

      test('should copy isCompleted only', () {
        final copied = model.copyWith(isCompleted: true);
        expect(copied.isCompleted, true);
        expect(copied.id, model.id);
      });

      test('should copy parentId only', () {
        final copied = model.copyWith(parentId: 'parent-task');
        expect(copied.parentId, 'parent-task');
        expect(copied.id, model.id);
      });

      test('should copy createdAt only', () {
        final newDate = DateTime(2025, 1, 1);
        final copied = model.copyWith(createdAt: newDate);
        expect(copied.createdAt, newDate);
        expect(copied.id, model.id);
      });

      test('should copy updatedAt only', () {
        final newDate = DateTime(2025, 6, 15);
        final copied = model.copyWith(updatedAt: newDate);
        expect(copied.updatedAt, newDate);
        expect(copied.id, model.id);
      });

      test('should copy completedAt only', () {
        final completedDate = DateTime(2024, 1, 16);
        final copied = model.copyWith(completedAt: completedDate);
        expect(copied.completedAt, completedDate);
        expect(copied.id, model.id);
      });

      test('should copy multiple fields', () {
        final copied = model.copyWith(
          title: 'New Title',
          importance: 2,
          isCompleted: true,
          completedAt: now,
        );
        expect(copied.title, 'New Title');
        expect(copied.importance, 2);
        expect(copied.isCompleted, true);
        expect(copied.completedAt, now);
        expect(copied.id, model.id);
      });

      test('copyWith with null does not clear nullable fields (uses ?? semantics)', () {
        final withDescription = model.copyWith(description: 'some desc');
        expect(withDescription.description, 'some desc');

        // Note: copyWith uses ?? operator, so passing null preserves existing value
        // This is the expected behavior - copyWith(null) means "don't change"
        final notCleared = withDescription.copyWith(description: null);
        expect(notCleared.description, 'some desc');
      });
    });

    group('importance enum values', () {
      test('0 should represent low importance', () {
        final lowImportanceTask = model.copyWith(importance: 0);
        expect(lowImportanceTask.importance, 0);
      });

      test('1 should represent medium importance', () {
        final mediumImportanceTask = model.copyWith(importance: 1);
        expect(mediumImportanceTask.importance, 1);
      });

      test('2 should represent high importance', () {
        final highImportanceTask = model.copyWith(importance: 2);
        expect(highImportanceTask.importance, 2);
      });
    });

    group('fromRow', () {
      test('should create TaskModel from Todo', () {
        final todo = Todo(
          id: 'todo-1',
          title: 'Test Task',
          description: 'Test Description',
          estimatedDuration: 1800,
          importance: 2,
          plannedStartTime: DateTime(2024, 2, 1, 10, 0),
          isCompleted: true,
          parentId: 'parent-1',
          createdAt: now,
          updatedAt: now,
          completedAt: now,
        );

        final result = TaskModel.fromRow(todo);

        expect(result.id, 'todo-1');
        expect(result.title, 'Test Task');
        expect(result.description, 'Test Description');
        expect(result.estimatedDuration, 1800);
        expect(result.importance, 2);
        expect(result.plannedStartTime, DateTime(2024, 2, 1, 10, 0));
        expect(result.isCompleted, true);
        expect(result.parentId, 'parent-1');
        expect(result.createdAt, now);
        expect(result.updatedAt, now);
        expect(result.completedAt, now);
      });

      test('should handle null optional fields', () {
        final todo = Todo(
          id: 'todo-2',
          title: 'Minimal Task',
          description: null,
          estimatedDuration: null,
          importance: 0,
          plannedStartTime: null,
          isCompleted: false,
          parentId: null,
          createdAt: now,
          updatedAt: now,
          completedAt: null,
        );

        final result = TaskModel.fromRow(todo);

        expect(result.id, 'todo-2');
        expect(result.description, null);
        expect(result.estimatedDuration, null);
        expect(result.plannedStartTime, null);
        expect(result.parentId, null);
        expect(result.completedAt, null);
      });
    });

    group('toCompanion', () {
      test('should convert to TodosCompanion with all fields', () {
        final insertable = model.toCompanion();
        // Cast to TodosCompanion to access Value fields
        final companion = insertable as TodosCompanion;

        expect(companion.id.value, 'task-1');
        expect(companion.title.value, 'Complete project');
        expect(companion.description.value, 'Finish the Flutter project');
        expect(companion.estimatedDuration.value, 3600);
        expect(companion.importance.value, 1);
        expect(companion.plannedStartTime.value, DateTime(2024, 1, 15, 14, 0));
        expect(companion.isCompleted.value, false);
        expect(companion.parentId.present, false);
        expect(companion.createdAt.value, now);
        expect(companion.updatedAt.value, now);
        expect(companion.completedAt.present, false);
      });

      test('should handle null optional fields', () {
        final modelWithNulls = TaskModel(
          id: 'task-2',
          title: 'Simple Task',
          description: null,
          estimatedDuration: null,
          importance: 1,
          plannedStartTime: null,
          isCompleted: false,
          parentId: null,
          createdAt: now,
          updatedAt: now,
          completedAt: null,
        );

        final insertable = modelWithNulls.toCompanion();
        final companion = insertable as TodosCompanion;

        expect(companion.id.value, 'task-2');
        expect(companion.description.present, false);
        expect(companion.estimatedDuration.present, false);
        expect(companion.plannedStartTime.present, false);
        expect(companion.parentId.present, false);
        expect(companion.completedAt.present, false);
      });

      test('should handle completed task with completedAt', () {
        final completedDate = DateTime(2024, 1, 16, 15, 30);
        final completedModel = model.copyWith(
          isCompleted: true,
          completedAt: completedDate,
        );

        final insertable = completedModel.toCompanion();
        final companion = insertable as TodosCompanion;

        expect(companion.isCompleted.value, true);
        expect(companion.completedAt.present, true);
        expect(companion.completedAt.value, completedDate);
      });
    });
  });
}
