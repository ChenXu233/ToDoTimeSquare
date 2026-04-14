import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_time_square/models/entities/habit_model.dart';
import 'package:todo_time_square/models/database/app_database.dart';

void main() {
  group('HabitEntity', () {
    late HabitEntity entity;
    late DateTime now;

    setUp(() {
      now = DateTime(2024, 1, 15, 10, 30);
      entity = HabitEntity(
        id: 'habit-1',
        name: 'Exercise',
        description: 'Daily exercise',
        targetType: 0,
        targetValue: 30,
        color: '#FF5733',
        icon: 'fitness_center',
        isActive: true,
        createdAt: now,
        archivedAt: null,
      );
    });

    group('copyWith', () {
      test('should copy id only', () {
        final copied = entity.copyWith(id: 'habit-2');
        expect(copied.id, 'habit-2');
        expect(copied.name, entity.name);
        expect(copied.description, entity.description);
        expect(copied.targetType, entity.targetType);
        expect(copied.targetValue, entity.targetValue);
        expect(copied.color, entity.color);
        expect(copied.icon, entity.icon);
        expect(copied.isActive, entity.isActive);
        expect(copied.createdAt, entity.createdAt);
        expect(copied.archivedAt, entity.archivedAt);
      });

      test('should copy name only', () {
        final copied = entity.copyWith(name: 'New Exercise');
        expect(copied.name, 'New Exercise');
        expect(copied.id, entity.id);
      });

      test('should copy description only', () {
        final copied = entity.copyWith(description: 'New description');
        expect(copied.description, 'New description');
        expect(copied.id, entity.id);
      });

      test('should copy targetType only', () {
        final copied = entity.copyWith(targetType: 1);
        expect(copied.targetType, 1);
        expect(copied.id, entity.id);
      });

      test('should copy targetValue only', () {
        final copied = entity.copyWith(targetValue: 60);
        expect(copied.targetValue, 60);
        expect(copied.id, entity.id);
      });

      test('should copy color only', () {
        final copied = entity.copyWith(color: '#00FF00');
        expect(copied.color, '#00FF00');
        expect(copied.id, entity.id);
      });

      test('should copy icon only', () {
        final copied = entity.copyWith(icon: 'new_icon');
        expect(copied.icon, 'new_icon');
        expect(copied.id, entity.id);
      });

      test('should copy isActive only', () {
        final copied = entity.copyWith(isActive: false);
        expect(copied.isActive, false);
        expect(copied.id, entity.id);
      });

      test('should copy createdAt only', () {
        final newDate = DateTime(2025, 1, 1);
        final copied = entity.copyWith(createdAt: newDate);
        expect(copied.createdAt, newDate);
        expect(copied.id, entity.id);
      });

      test('should copy archivedAt only', () {
        final archivedDate = DateTime(2024, 6, 1);
        final copied = entity.copyWith(archivedAt: archivedDate);
        expect(copied.archivedAt, archivedDate);
        expect(copied.id, entity.id);
      });

      test('should copy multiple fields', () {
        final copied = entity.copyWith(
          name: 'New Name',
          targetType: 1,
          isActive: false,
        );
        expect(copied.name, 'New Name');
        expect(copied.targetType, 1);
        expect(copied.isActive, false);
        expect(copied.id, entity.id);
        expect(copied.description, entity.description);
      });
    });

    group('targetTypeEnum', () {
      test('should return daily when targetType is 0', () {
        final dailyEntity = entity.copyWith(targetType: 0);
        expect(dailyEntity.targetTypeEnum, HabitTargetType.daily);
      });

      test('should return weekly when targetType is 1', () {
        final weeklyEntity = entity.copyWith(targetType: 1);
        expect(weeklyEntity.targetTypeEnum, HabitTargetType.weekly);
      });
    });

    group('isDaily and isWeekly shortcuts', () {
      test('isDaily returns true when targetType is 0', () {
        final dailyEntity = entity.copyWith(targetType: 0);
        expect(dailyEntity.isDaily, true);
        expect(dailyEntity.isWeekly, false);
      });

      test('isWeekly returns true when targetType is 1', () {
        final weeklyEntity = entity.copyWith(targetType: 1);
        expect(weeklyEntity.isWeekly, true);
        expect(weeklyEntity.isDaily, false);
      });
    });

    group('fromRow', () {
      test('should create HabitEntity from Habit', () {
        final habit = Habit(
          id: 'test-id',
          name: 'Test Habit',
          description: 'Test Description',
          targetType: 1,
          targetValue: 5,
          color: '#ABCDEF',
          icon: 'star',
          isActive: true,
          createdAt: now,
          archivedAt: null,
        );

        final result = HabitEntity.fromRow(habit);

        expect(result.id, 'test-id');
        expect(result.name, 'Test Habit');
        expect(result.description, 'Test Description');
        expect(result.targetType, 1);
        expect(result.targetValue, 5);
        expect(result.color, '#ABCDEF');
        expect(result.icon, 'star');
        expect(result.isActive, true);
        expect(result.createdAt, now);
        expect(result.archivedAt, null);
      });

      test('should handle null description and optional fields', () {
        final habit = Habit(
          id: 'test-id',
          name: 'Test Habit',
          description: null,
          targetType: 0,
          targetValue: 1,
          color: null,
          icon: null,
          isActive: false,
          createdAt: now,
          archivedAt: DateTime(2024, 1, 1),
        );

        final result = HabitEntity.fromRow(habit);

        expect(result.id, 'test-id');
        expect(result.description, null);
        expect(result.color, null);
        expect(result.icon, null);
        expect(result.isActive, false);
        expect(result.archivedAt, DateTime(2024, 1, 1));
      });
    });

    group('toCompanion', () {
      test('should convert to HabitsCompanion with all fields', () {
        final insertable = entity.toCompanion();
        // Cast to HabitsCompanion to access Value fields
        final companion = insertable as HabitsCompanion;

        expect(companion.id.value, 'habit-1');
        expect(companion.name.value, 'Exercise');
        expect(companion.description.value, 'Daily exercise');
        expect(companion.targetType.value, 0);
        expect(companion.targetValue.value, 30);
        expect(companion.color.value, '#FF5733');
        expect(companion.icon.value, 'fitness_center');
        expect(companion.isActive.value, true);
        expect(companion.createdAt.value, now);
        expect(companion.archivedAt.present, false);
      });

      test('should handle null optional fields', () {
        final entityWithNulls = HabitEntity(
          id: 'habit-2',
          name: 'Simple Habit',
          description: null,
          targetType: 0,
          targetValue: 1,
          color: null,
          icon: null,
          isActive: true,
          createdAt: now,
          archivedAt: null,
        );

        final insertable = entityWithNulls.toCompanion();
        final companion = insertable as HabitsCompanion;

        expect(companion.id.value, 'habit-2');
        expect(companion.description.present, false);
        expect(companion.color.present, false);
        expect(companion.icon.present, false);
        expect(companion.archivedAt.present, false);
      });

      test('should handle archivedAt with value', () {
        final archivedDate = DateTime(2024, 6, 1);
        final entityWithArchive = entity.copyWith(archivedAt: archivedDate);

        final insertable = entityWithArchive.toCompanion();
        final companion = insertable as HabitsCompanion;

        expect(companion.archivedAt.present, true);
        expect(companion.archivedAt.value, archivedDate);
      });
    });
  });
}
