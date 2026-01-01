import 'package:drift/drift.dart';
import 'database_factory.dart';
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
    // 工厂模式：使用 drift_flutter 隐藏平台差异
    return DatabaseFactory.createExecutor();
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
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
