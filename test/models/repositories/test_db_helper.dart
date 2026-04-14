import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:todo_time_square/models/database/app_database.dart';

/// 创建内存数据库用于测试
AppDatabase createTestDb() {
  final db = AppDatabase(NativeDatabase.memory());
  return db;
}
