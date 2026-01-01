import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'schema/todos.dart';
import 'schema/focus_records.dart';
import 'schema/habits.dart';
import 'schema/habit_logs.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Todos, FocusRecords, Habits, HabitLogs],
)
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance!;

  @override
  int get schemaVersion => 2;

  AppDatabase(super.executor);

  static Future<AppDatabase> getInstance() async {
    _instance ??= AppDatabase(await _createExecutor());
    return _instance!;
  }

  static Future<QueryExecutor> _createExecutor() async {
    if (kIsWeb) {
      return NativeDatabase.memory();
    }
    final dbPath = await _getDatabasePath();
    return NativeDatabase(
      File(p.join(dbPath, 'todo_time_square.db')),
      logStatements: kDebugMode,
    );
  }

  static Future<String> _getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // 从版本 1 升级到版本 2：创建习惯相关表
          await m.createTable(habits);
          await m.createTable(habitLogs);
        }
      },
    );
  }

  static Future<void> closeDatabase() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }
}
