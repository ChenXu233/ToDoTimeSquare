// Sync service for incremental data synchronization
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dtos/sync_dto.dart';
import '../models/database/app_database.dart';
import '../models/dtos/sync_settings.dart';
import 'auth_service.dart';

/// 同步异常
class SyncException implements Exception {
  final String message;
  final int? statusCode;
  final SyncErrorCode? errorCode;

  SyncException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'SyncException: $message (status: ${statusCode ?? "N/A"})';
}

/// 同步错误码
enum SyncErrorCode {
  networkError,
  serverError,
  unauthorized,
  conflict,
  timeout,
  unknown,
}

/// 同步进度状态
enum SyncProgressState {
  idle,
  preparing,
  uploading,
  downloading,
  merging,
  completed,
  error,
}

/// 同步进度信息
class SyncProgress {
  final SyncProgressState state;
  final int totalRecords;
  final int processedRecords;
  final String? message;
  final int? conflictsCount;
  final DateTime? lastSyncTime;

  SyncProgress({
    required this.state,
    this.totalRecords = 0,
    this.processedRecords = 0,
    this.message,
    this.conflictsCount,
    this.lastSyncTime,
  });

  double get progress {
    if (totalRecords == 0) return 0;
    return processedRecords / totalRecords;
  }

  String get progressText {
    if (state == SyncProgressState.idle) return '就绪';
    if (state == SyncProgressState.preparing) return '准备中...';
    if (state == SyncProgressState.uploading) return '上传中 $processedRecords/$totalRecords';
    if (state == SyncProgressState.downloading) return '下载中 $processedRecords/$totalRecords';
    if (state == SyncProgressState.merging) return '合并中...';
    if (state == SyncProgressState.completed) return '同步完成';
    if (state == SyncProgressState.error) return '同步失败';
    return '';
  }
}

class SyncService with ChangeNotifier {
  static const String _syncEndpoint = '/sync';
  static const String _resolveEndpoint = '/sync/resolve';

  final AuthService authService;
  final SyncSettings syncSettings;
  final Duration timeout;

  String get baseUrl => syncSettings.baseUrl;

  SyncProgressState _progressState = SyncProgressState.idle;
  int _totalRecords = 0;
  int _processedRecords = 0;
  int? _conflictsCount;
  DateTime? _lastSyncTime;

  SyncProgressState get progressState => _progressState;
  int get totalRecords => _totalRecords;
  int get processedRecords => _processedRecords;
  int? get conflictsCount => _conflictsCount;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncService({
    required this.authService,
    required this.syncSettings,
    this.timeout = const Duration(seconds: 30),
  });

  /// 执行增量同步
  Future<SyncResponse> sync(String accessToken) async {
    _updateProgress(SyncProgressState.preparing, message: '准备同步数据...');

    try {
      // 1. 获取待同步的变更记录
      _updateProgress(SyncProgressState.preparing, message: '收集变更数据...');
      final pendingRecords = await _getPendingRecords();

      _totalRecords = pendingRecords.length;
      _processedRecords = 0;

      // 2. 构建同步请求
      final request = SyncRequest(
        clientTimestamp: await _getLastSyncTimestamp(),
        records: pendingRecords,
        userId: await _getUserId(accessToken),
        deviceId: await _getDeviceId(),
      );

      // 3. 发送同步请求
      _updateProgress(SyncProgressState.uploading, message: '上传变更数据...');
      final response = await _sendSyncRequest(request, accessToken);

      if (!response.success) {
        _updateProgress(SyncProgressState.error, message: response.message ?? '同步失败');
        throw SyncException(response.message ?? '同步失败', errorCode: SyncErrorCode.serverError);
      }

      // 4. 合并服务器变更
      if (response.serverRecords.isNotEmpty) {
        _updateProgress(SyncProgressState.downloading,
            totalRecords: response.serverRecords.length,
            message: '下载服务器变更...');
        await _mergeServerRecords(response.serverRecords);
      }

      // 5. 更新同步状态
      _updateProgress(SyncProgressState.merging, message: '更新本地状态...');
      await _setLastSyncTimestamp(response.serverTimestamp);

      // 6. 处理冲突
      if (response.conflicts.isNotEmpty) {
        _conflictsCount = response.conflicts.length;
        _updateProgress(SyncProgressState.merging,
            conflictsCount: response.conflicts.length, message: '发现 ${response.conflicts.length} 个冲突');
      } else {
        _conflictsCount = null;
      }

      _lastSyncTime = DateTime.now();
      _updateProgress(SyncProgressState.completed, message: '同步成功');

      return response;
    } catch (e) {
      _updateProgress(SyncProgressState.error, message: e.toString());
      rethrow;
    }
  }

  /// 解决冲突
  Future<void> resolveConflict(
    String entityType,
    String entityId,
    bool keepLocal,
    String accessToken,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_resolveEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'entity_type': entityType,
        'entity_id': entityId,
        'keep_local': keepLocal,
      }),
    ).timeout(timeout);

    if (response.statusCode == 200) {
      _conflictsCount = (_conflictsCount ?? 1) - 1;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw SyncException(error['detail'] ?? '解决冲突失败', statusCode: response.statusCode);
    }
  }

  /// 获取待同步的变更记录
  /// 直接查询各业务表中自上次同步以来有变更的记录
  Future<List<SyncRecord>> _getPendingRecords() async {
    final db = await AppDatabase.getInstance();
    final records = <SyncRecord>[];
    
    // 获取上次同步时间戳（毫秒）- 放在前面以便调试打印
    final lastSyncTimestamp = await _getLastSyncTimestamp();
    
    final lastSyncTime = lastSyncTimestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp)
        : DateTime.fromMillisecondsSinceEpoch(0);

    if (kDebugMode) {
      final allTodos = await db.select(db.todos).get();
      final todos = await (db.select(
        db.todos,
      )..where((t) => t.updatedAt.isBiggerThanValue(lastSyncTime))).get();
      print('查询到 ${todos.length} 条 todos（条件: updatedAt > $lastSyncTime）');
      print('lastSyncTimestamp: $lastSyncTimestamp');
      if (allTodos.isNotEmpty) {
        print('第一条记录的updatedAt: ${allTodos.first.updatedAt}');
      }
      print('todos表总记录数: ${allTodos.length}');
    }

    try {
      // 1. 查询有变更的 Todos
      final todos = await (db.select(db.todos)
            ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncTime)))
          .get();
      for (final todo in todos) {
        records.add(SyncRecord(
          id: 'todo_${todo.id}',
          entityType: 'todo',
          entityId: todo.id,
          operation: todo.id.startsWith('_') ? 'create' : 'update',
          data: {
            'id': todo.id,
            'title': todo.title,
            'description': todo.description,
            'estimated_duration': todo.estimatedDuration,
            'importance': todo.importance,
            'planned_start_time': todo.plannedStartTime?.millisecondsSinceEpoch,
            'is_completed': todo.isCompleted ? 1 : 0,
            'parent_id': todo.parentId,
            'created_at': todo.createdAt.millisecondsSinceEpoch,
            'updated_at': todo.updatedAt.millisecondsSinceEpoch,
            'completed_at': todo.completedAt?.millisecondsSinceEpoch,
          },
          timestamp: todo.updatedAt.millisecondsSinceEpoch,
          version: 1,
        ));
      }

      // 2. 查询有变更的 FocusRecords
      final focusRecords = await (db.select(db.focusRecords)
            ..where((t) => t.createdAt.isBiggerThanValue(lastSyncTime)))
          .get();
      for (final fr in focusRecords) {
        records.add(SyncRecord(
          id: 'focus_record_${fr.id}',
          entityType: 'focus_record',
          entityId: fr.id,
          operation: 'create',
          data: {
            'id': fr.id,
            'task_id': fr.taskId,
            'task_title': fr.taskTitle,
            'start_time': fr.startTime.millisecondsSinceEpoch,
            'duration_seconds': fr.durationSeconds,
            'is_completed': fr.isCompleted ? 1 : 0,
            'interruption_count': fr.interruptionCount,
            'efficiency_score': fr.efficiencyScore,
            'created_at': fr.createdAt.millisecondsSinceEpoch,
          },
          timestamp: fr.createdAt.millisecondsSinceEpoch,
          version: 1,
        ));
      }

      // 3. 查询有变更的 Habits
      final habits = await (db.select(db.habits)
            ..where((t) => t.createdAt.isBiggerThanValue(lastSyncTime)))
          .get();
      for (final habit in habits) {
        records.add(SyncRecord(
          id: 'habit_${habit.id}',
          entityType: 'habit',
          entityId: habit.id,
          operation: habit.id.startsWith('_') ? 'create' : 'update',
          data: {
            'id': habit.id,
            'name': habit.name,
            'description': habit.description,
            'target_type': habit.targetType,
            'target_value': habit.targetValue,
            'color': habit.color,
            'icon': habit.icon,
            'is_active': habit.isActive ? 1 : 0,
            'created_at': habit.createdAt.millisecondsSinceEpoch,
            'archived_at': habit.archivedAt?.millisecondsSinceEpoch,
          },
          timestamp: habit.createdAt.millisecondsSinceEpoch,
          version: 1,
        ));
      }

      // 4. 查询有变更的 HabitLogs
      final habitLogs = await (db.select(db.habitLogs)
            ..where((t) => t.createdAt.isBiggerThanValue(lastSyncTime)))
          .get();
      for (final log in habitLogs) {
        records.add(SyncRecord(
          id: 'habit_log_${log.id}',
          entityType: 'habit_log',
          entityId: log.id,
          operation: 'create',
          data: {
            'id': log.id,
            'habit_id': log.habitId,
            'date': log.date.millisecondsSinceEpoch,
            'completed_value': log.completedValue,
            'notes': log.notes,
            'created_at': log.createdAt.millisecondsSinceEpoch,
          },
          timestamp: log.createdAt.millisecondsSinceEpoch,
          version: 1,
        ));
      }

      // 5. 查询有变更的 Tags
      final tags = await (db.select(db.taskTags)
            ..where((t) => t.createdAt.isBiggerThanValue(lastSyncTime)))
          .get();
      for (final tag in tags) {
        records.add(SyncRecord(
          id: 'tag_${tag.id}',
          entityType: 'tag',
          entityId: tag.id,
          operation: tag.id.startsWith('_') ? 'create' : 'update',
          data: {
            'id': tag.id,
            'user_id': tag.userId,
            'name': tag.name,
            'color': tag.color,
            'type': tag.type,
            'icon': tag.icon,
            'is_preset': tag.isPreset ? 1 : 0,
            'usage_count': tag.usageCount,
            'created_at': tag.createdAt.millisecondsSinceEpoch,
            'updated_at': tag.updatedAt.millisecondsSinceEpoch,
          },
          timestamp: tag.createdAt.millisecondsSinceEpoch,
          version: 1,
        ));
      }

      // 6. 查询有变更的 TagRelations
      final tagRelations = await (db.select(db.taskTagRelations)
            ..where((t) => t.createdAt.isBiggerThanValue(lastSyncTime)))
          .get();
      for (final rel in tagRelations) {
        records.add(SyncRecord(
          id: 'tag_relation_${rel.id}',
          entityType: 'tag_relation',
          entityId: rel.id,
          operation: 'create',
          data: {
            'id': rel.id,
            'todo_id': rel.todoId,
            'tag_id': rel.tagId,
            'created_at': rel.createdAt.millisecondsSinceEpoch,
          },
          timestamp: rel.createdAt.millisecondsSinceEpoch,
          version: 1,
        ));
      }
    } catch (e) {
      // 忽略错误，返回已收集的记录
    }

    // 按时间戳排序
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return records;
  }

  /// 获取最后同步时间戳
  /// 如果时间戳是未来的（异常情况），重置为0
  Future<int> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_sync_timestamp') ?? 0;

    // 检查时间戳是否合理（不能大于当前设备时间）
    final now = DateTime.now().millisecondsSinceEpoch;
    if (timestamp > now) {
      // 时间戳是未来的，视为首次同步
      if (kDebugMode) {
        print('警告: lastSyncTimestamp($timestamp)是未来时间，重置为0');
      }
      await prefs.setInt('last_sync_timestamp', 0);
      return 0;
    }
    return timestamp;
  }

  /// 重置同步时间戳（用于全量同步）
  Future<void> resetSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_timestamp', 0);
    if (kDebugMode) {
      print('同步时间戳已重置，将执行全量同步');
    }
    notifyListeners();
  }

  /// 设置最后同步时间戳
  Future<void> _setLastSyncTimestamp(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_timestamp', timestamp);
  }

  /// 获取用户ID
  Future<String> _getUserId(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['id'].toString();
    }
    return 'unknown';
  }

  /// 获取设备ID
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  /// 发送同步请求
  Future<SyncResponse> _sendSyncRequest(SyncRequest request, String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_syncEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(request.toJson()),
    ).timeout(timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SyncResponse.fromJson(json);
    } else if (response.statusCode == 401) {
      throw SyncException('未授权，请重新登录', statusCode: 401, errorCode: SyncErrorCode.unauthorized);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw SyncException(
        error['detail'] ?? '同步请求失败',
        statusCode: response.statusCode,
        errorCode: SyncErrorCode.serverError,
      );
    }
  }

  /// 合并服务器变更记录
  Future<void> _mergeServerRecords(List<SyncRecord> records) async {
    final db = await AppDatabase.getInstance();

    for (final record in records) {
      _processedRecords++;

      switch (record.entityType) {
        case 'todo':
          await _mergeTodo(db, record);
          break;
        case 'focus_record':
          await _mergeFocusRecord(db, record);
          break;
        case 'habit':
          await _mergeHabit(db, record);
          break;
        case 'habit_log':
          await _mergeHabitLog(db, record);
          break;
        case 'tag':
          await _mergeTag(db, record);
          break;
        case 'tag_relation':
          await _mergeTagRelation(db, record);
          break;
      }
    }
  }

  Future<void> _mergeTodo(AppDatabase db, SyncRecord record) async {
    final data = record.data ?? {};
    final now = DateTime.now();

    if (record.operation == 'delete') {
      await (db.delete(db.todos)
            ..where((t) => t.id.equals(record.entityId)))
          .go();
    } else {
      final existing = await (db.select(db.todos)
            ..where((t) => t.id.equals(record.entityId)))
          .get();

      final createdAt = data['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
          : now;
      final completedAt = data['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completed_at'])
          : null;
      final plannedStartTime = data['planned_start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['planned_start_time'])
          : null;

      if (existing.isNotEmpty) {
        await (db.update(db.todos)
              ..where((t) => t.id.equals(record.entityId)))
            .write(TodosCompanion(
              id: drift.Value(record.entityId),
              title: drift.Value(data['title'] ?? ''),
              description: drift.Value(data['description']),
              estimatedDuration: drift.Value(data['estimated_duration']),
              importance: drift.Value(data['importance'] ?? 1),
              plannedStartTime: drift.Value(plannedStartTime),
              isCompleted: drift.Value((data['is_completed'] ?? 0) == 1),
              parentId: drift.Value(data['parent_id']),
              createdAt: drift.Value(createdAt),
              updatedAt: drift.Value(now),
              completedAt: drift.Value(completedAt),
            ));
      } else {
        await db.into(db.todos).insert(TodosCompanion(
          id: drift.Value(record.entityId),
          title: drift.Value(data['title'] ?? ''),
          description: drift.Value(data['description']),
          estimatedDuration: drift.Value(data['estimated_duration']),
          importance: drift.Value(data['importance'] ?? 1),
          plannedStartTime: drift.Value(plannedStartTime),
          isCompleted: drift.Value((data['is_completed'] ?? 0) == 1),
          parentId: drift.Value(data['parent_id']),
          createdAt: drift.Value(createdAt),
          updatedAt: drift.Value(now),
          completedAt: drift.Value(completedAt),
        ));
      }
    }
  }

  Future<void> _mergeFocusRecord(AppDatabase db, SyncRecord record) async {
    final data = record.data ?? {};
    final now = DateTime.now();
    final createdAt = data['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
        : now;
    final startTime = data['start_time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['start_time'])
        : now;

    final existing = await (db.select(db.focusRecords)
          ..where((t) => t.id.equals(record.entityId)))
          .get();

    if (existing.isNotEmpty) {
      await (db.update(db.focusRecords)
            ..where((t) => t.id.equals(record.entityId)))
          .write(FocusRecordsCompanion(
            id: drift.Value(record.entityId),
            taskId: drift.Value(data['task_id']),
            taskTitle: drift.Value(data['task_title']),
            startTime: drift.Value(startTime),
            durationSeconds: drift.Value(data['duration_seconds']),
            isCompleted: drift.Value((data['is_completed'] ?? 0) == 1),
            interruptionCount: drift.Value(data['interruption_count'] ?? 0),
            efficiencyScore: drift.Value(data['efficiency_score']),
            createdAt: drift.Value(createdAt),
          ));
    } else {
      await db.into(db.focusRecords).insert(FocusRecordsCompanion(
        id: drift.Value(record.entityId),
        taskId: drift.Value(data['task_id']),
        taskTitle: drift.Value(data['task_title']),
        startTime: drift.Value(startTime),
        durationSeconds: drift.Value(data['duration_seconds']),
        isCompleted: drift.Value((data['is_completed'] ?? 0) == 1),
        interruptionCount: drift.Value(data['interruption_count'] ?? 0),
        efficiencyScore: drift.Value(data['efficiency_score']),
        createdAt: drift.Value(createdAt),
      ));
    }
  }

  Future<void> _mergeHabit(AppDatabase db, SyncRecord record) async {
    final data = record.data ?? {};
    final now = DateTime.now();
    final createdAt = data['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
        : now;
    final archivedAt = data['archived_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['archived_at'])
        : null;

    final existing = await (db.select(db.habits)
          ..where((t) => t.id.equals(record.entityId)))
          .get();

    if (existing.isNotEmpty) {
      await (db.update(db.habits)
            ..where((t) => t.id.equals(record.entityId)))
          .write(HabitsCompanion(
            id: drift.Value(record.entityId),
            name: drift.Value(data['name'] ?? ''),
            description: drift.Value(data['description']),
            targetType: drift.Value(data['target_type'] ?? 0),
            targetValue: drift.Value(data['target_value'] ?? 1),
            color: drift.Value(data['color']),
            icon: drift.Value(data['icon']),
            isActive: drift.Value((data['is_active'] ?? 1) == 1),
            createdAt: drift.Value(createdAt),
            archivedAt: drift.Value(archivedAt),
          ));
    } else {
      await db.into(db.habits).insert(HabitsCompanion(
        id: drift.Value(record.entityId),
        name: drift.Value(data['name'] ?? ''),
        description: drift.Value(data['description']),
        targetType: drift.Value(data['target_type'] ?? 0),
        targetValue: drift.Value(data['target_value'] ?? 1),
        color: drift.Value(data['color']),
        icon: drift.Value(data['icon']),
        isActive: drift.Value((data['is_active'] ?? 1) == 1),
        createdAt: drift.Value(createdAt),
        archivedAt: drift.Value(archivedAt),
      ));
    }
  }

  Future<void> _mergeHabitLog(AppDatabase db, SyncRecord record) async {
    final data = record.data ?? {};
    final now = DateTime.now();
    final createdAt = data['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
        : now;
    final date = data['date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['date'])
        : now;

    final existing = await (db.select(db.habitLogs)
          ..where((t) => t.id.equals(record.entityId)))
          .get();

    if (existing.isNotEmpty) {
      await (db.update(db.habitLogs)
            ..where((t) => t.id.equals(record.entityId)))
          .write(HabitLogsCompanion(
            id: drift.Value(record.entityId),
            habitId: drift.Value(data['habit_id'] ?? ''),
            date: drift.Value(date),
            completedValue: drift.Value(data['completed_value'] ?? 1),
            notes: drift.Value(data['notes']),
            createdAt: drift.Value(createdAt),
          ));
    } else {
      await db.into(db.habitLogs).insert(HabitLogsCompanion(
        id: drift.Value(record.entityId),
        habitId: drift.Value(data['habit_id'] ?? ''),
        date: drift.Value(date),
        completedValue: drift.Value(data['completed_value'] ?? 1),
        notes: drift.Value(data['notes']),
        createdAt: drift.Value(createdAt),
      ));
    }
  }

  Future<void> _mergeTag(AppDatabase db, SyncRecord record) async {
    final data = record.data ?? {};
    final now = DateTime.now();
    final createdAt = data['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
        : now;

    final existing = await (db.select(db.taskTags)
          ..where((t) => t.id.equals(record.entityId)))
          .get();

    if (existing.isNotEmpty) {
      await (db.update(db.taskTags)
            ..where((t) => t.id.equals(record.entityId)))
          .write(TaskTagsCompanion(
            id: drift.Value(record.entityId),
            userId: drift.Value(data['user_id'] ?? 'local'),
            name: drift.Value(data['name'] ?? ''),
            color: drift.Value(data['color'] ?? '#000000'),
            type: drift.Value(data['type'] ?? 0),
            icon: drift.Value(data['icon']),
            isPreset: drift.Value((data['is_preset'] ?? 0) == 1),
            usageCount: drift.Value(data['usage_count'] ?? 0),
            createdAt: drift.Value(createdAt),
            updatedAt: drift.Value(now),
          ));
    } else {
      await db.into(db.taskTags).insert(TaskTagsCompanion(
        id: drift.Value(record.entityId),
        userId: drift.Value(data['user_id'] ?? 'local'),
        name: drift.Value(data['name'] ?? ''),
        color: drift.Value(data['color'] ?? '#000000'),
        type: drift.Value(data['type'] ?? 0),
        icon: drift.Value(data['icon']),
        isPreset: drift.Value((data['is_preset'] ?? 0) == 1),
        usageCount: drift.Value(data['usage_count'] ?? 0),
        createdAt: drift.Value(createdAt),
        updatedAt: drift.Value(now),
      ));
    }
  }

  Future<void> _mergeTagRelation(AppDatabase db, SyncRecord record) async {
    final data = record.data ?? {};
    final createdAt = data['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
        : DateTime.now();

    final existing = await (db.select(db.taskTagRelations)
          ..where((t) => t.id.equals(record.entityId)))
          .get();

    if (existing.isNotEmpty) {
      await (db.update(db.taskTagRelations)
            ..where((t) => t.id.equals(record.entityId)))
          .write(TaskTagRelationsCompanion(
            id: drift.Value(record.entityId),
            todoId: drift.Value(data['todo_id'] ?? ''),
            tagId: drift.Value(data['tag_id'] ?? ''),
            createdAt: drift.Value(createdAt),
          ));
    } else {
      await db.into(db.taskTagRelations).insert(TaskTagRelationsCompanion(
        id: drift.Value(record.entityId),
        todoId: drift.Value(data['todo_id'] ?? ''),
        tagId: drift.Value(data['tag_id'] ?? ''),
        createdAt: drift.Value(createdAt),
      ));
    }
  }

  void _updateProgress(
    SyncProgressState state, {
    int totalRecords = 0,
    int processedRecords = 0,
    String? message,
    int? conflictsCount,
  }) {
    _progressState = state;
    if (totalRecords > 0) _totalRecords = totalRecords;
    if (processedRecords > 0) _processedRecords = processedRecords;
    if (conflictsCount != null) _conflictsCount = conflictsCount;
    notifyListeners();
  }

  /// 重置同步进度状态
  void resetProgress() {
    _progressState = SyncProgressState.idle;
    _totalRecords = 0;
    _processedRecords = 0;
    _conflictsCount = null;
    notifyListeners();
  }
}
