import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

/// 数据库工厂
class DatabaseFactory {
  /// 创建数据库执行器
  /// 使用 drift_flutter 自动处理所有平台的差异
  static QueryExecutor createExecutor() {
    return driftDatabase(
      name: 'todo_time_square_db',
      // Web 平台：配置 WASM 文件路径
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
              // 回调：显示选择了哪种存储实现
              onResult: (result) {
                print('========================================');
                print('Drift Web 数据库初始化结果:');
                print('选择的实现: ${result.chosenImplementation}');
                print('缺失的功能: ${result.missingFeatures}');
                print('========================================');
              },
            )
          : null,
    );
  }
}
