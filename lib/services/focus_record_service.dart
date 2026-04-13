import '../models/database/database_initializer.dart';
import '../models/repositories/focus_record_repository.dart';

/// 专注记录服务
/// 提供专注记录的创建和查询功能，不依赖 Provider
class FocusRecordService {
  late final FocusRecordRepository _repository;

  FocusRecordService() {
    _repository = FocusRecordRepository(DatabaseInitializer().database);
  }

  /// 创建专注记录
  Future<void> addRecord(FocusRecordModel record) async {
    await _repository.createRecord(record);
  }

  /// 获取所有记录（按时间倒序）
  Future<List<FocusRecordModel>> getAllRecords() async {
    return _repository.getAllRecords();
  }

  /// 获取最近 N 条记录
  Future<List<FocusRecordModel>> getRecentRecords(int limit) async {
    return _repository.getRecentRecords(limit);
  }

  /// 按任务 ID 获取记录
  Future<List<FocusRecordModel>> getRecordsByTaskId(String taskId) async {
    return _repository.getRecordsByTaskId(taskId);
  }
}
