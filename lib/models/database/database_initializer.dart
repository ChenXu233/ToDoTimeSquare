import 'app_database.dart';
import 'migration/migration_service.dart';

/// 数据库初始化服务
/// 管理数据库的创建、迁移和初始化
class DatabaseInitializer {
  static final DatabaseInitializer _instance = DatabaseInitializer._internal();
  factory DatabaseInitializer() => _instance;
  DatabaseInitializer._internal();

  AppDatabase? _database;
  bool _isInitialized = false;
  bool _migrationCompleted = false;

  /// 初始化数据库
  /// [enableMigration] 是否启用数据迁移（首次安装时启用）
  Future<InitializationResult> initialize({bool enableMigration = true}) async {
    if (_isInitialized) {
      return InitializationResult(
        success: true,
        message: '数据库已初始化',
      );
    }

    try {
      _database = await AppDatabase.getInstance();
      _isInitialized = true;

      // 检查并执行迁移
      if (enableMigration && !_migrationCompleted) {
        final migrationService = MigrationService(_database!);
        final needsMigration = await migrationService.needsMigration();

        if (needsMigration) {
          final result = await migrationService.migrateAll();
          _migrationCompleted = true;
          return InitializationResult(
            success: true,
            message: result.toString(),
            migrationResult: result,
          );
        }
      }

      return InitializationResult(
        success: true,
        message: '数据库初始化完成',
      );
    } catch (e) {
      return InitializationResult(
        success: false,
        message: '数据库初始化失败：$e',
        error: e,
      );
    }
  }

  /// 获取数据库实例
  AppDatabase get database {
    if (!_isInitialized || _database == null) {
      throw StateError('数据库未初始化，请先调用 initialize()');
    }
    return _database!;
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 检查迁移是否已完成
  bool get isMigrationCompleted => _migrationCompleted;

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await AppDatabase.closeDatabase();
      _database = null;
      _isInitialized = false;
    }
  }
}

/// 初始化结果
class InitializationResult {
  final bool success;
  final String message;
  final MigrationResult? migrationResult;
  final dynamic error;

  InitializationResult({
    required this.success,
    required this.message,
    this.migrationResult,
    this.error,
  });

  @override
  String toString() {
    return message;
  }
}
