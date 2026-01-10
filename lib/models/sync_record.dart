/// 同步操作类型
enum SyncOperation { create, update, delete }

/// 同步状态
enum SyncStatus { synced, pending, conflict }

/// 同步记录数据模型
/// 用于在客户端和服务器之间传输变更数据
class SyncRecord {
  /// 记录唯一标识
  final String id;

  /// 实体类型: 'todo' | 'focus_record' | 'habit' | 'habit_log' | 'tag' | 'tag_relation'
  final String entityType;

  /// 实体ID
  final String entityId;

  /// 操作类型: 'create' | 'update' | 'delete'
  final String operation;

  /// 实体数据（create/update 时包含）
  final Map<String, dynamic>? data;

  /// 变更时间戳（毫秒）
  final int timestamp;

  /// 版本号（用于冲突检测）
  final int version;

  SyncRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.data,
    required this.timestamp,
    required this.version,
  });

  /// 从 JSON 构造
  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      operation: json['operation'] as String,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as int,
      version: json['version'] as int,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'data': data,
      'timestamp': timestamp,
      'version': version,
    };
  }

  /// 从 SyncRecord 列表 JSON 构造
  static List<SyncRecord> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => SyncRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 转换为 JSON 列表
  static List<Map<String, dynamic>> listToJson(List<SyncRecord> records) {
    return records.map((r) => r.toJson()).toList();
  }

  @override
  String toString() {
    return 'SyncRecord(id: $id, entityType: $entityType, entityId: $entityId, '
        'operation: $operation, timestamp: $timestamp, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncRecord &&
        other.id == id &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.operation == operation &&
        other.timestamp == timestamp &&
        other.version == version;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      entityType.hashCode ^
      entityId.hashCode ^
      operation.hashCode ^
      timestamp.hashCode ^
      version.hashCode;
}

/// 冲突信息
class ConflictInfo {
  /// 实体类型
  final String entityType;

  /// 实体ID
  final String entityId;

  /// 本地版本号
  final int localVersion;

  /// 服务器版本号
  final int serverVersion;

  /// 本地数据
  final Map<String, dynamic> localData;

  /// 服务器数据
  final Map<String, dynamic> serverData;

  /// 本地最后修改时间
  final int localTimestamp;

  /// 服务器最后修改时间
  final int serverTimestamp;

  ConflictInfo({
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.serverVersion,
    required this.localData,
    required this.serverData,
    required this.localTimestamp,
    required this.serverTimestamp,
  });

  /// 从 JSON 构造
  factory ConflictInfo.fromJson(Map<String, dynamic> json) {
    return ConflictInfo(
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      localVersion: json['local_version'] as int,
      serverVersion: json['server_version'] as int,
      localData: json['local_data'] as Map<String, dynamic>,
      serverData: json['server_data'] as Map<String, dynamic>,
      localTimestamp: json['local_timestamp'] as int,
      serverTimestamp: json['server_timestamp'] as int,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'local_version': localVersion,
      'server_version': serverVersion,
      'local_data': localData,
      'server_data': serverData,
      'local_timestamp': localTimestamp,
      'server_timestamp': serverTimestamp,
    };
  }

  @override
  String toString() {
    return 'ConflictInfo(entityType: $entityType, entityId: $entityId, '
        'localVersion: $localVersion, serverVersion: $serverVersion)';
  }
}

/// 同步请求
class SyncRequest {
  /// 客户端最后同步时间戳
  final int clientTimestamp;

  /// 客户端变更记录列表
  final List<SyncRecord> records;

  /// 用户ID
  final String userId;

  /// 设备ID
  final String deviceId;

  SyncRequest({
    required this.clientTimestamp,
    required this.records,
    required this.userId,
    required this.deviceId,
  });

  /// 从 JSON 构造
  factory SyncRequest.fromJson(Map<String, dynamic> json) {
    return SyncRequest(
      clientTimestamp: json['client_timestamp'] as int,
      records: json['records'] != null
          ? SyncRecord.listFromJson(json['records'] as List)
          : [],
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'client_timestamp': clientTimestamp,
      'records': SyncRecord.listToJson(records),
      'user_id': userId,
      'device_id': deviceId,
    };
  }
}

/// 同步响应
class SyncResponse {
  /// 是否成功
  final bool success;

  /// 服务器当前时间戳
  final int serverTimestamp;

  /// 客户端变更应用数量
  final int clientApplied;

  /// 服务器端变更记录
  final List<SyncRecord> serverRecords;

  /// 冲突列表
  final List<ConflictInfo> conflicts;

  /// 状态消息
  final String? message;

  SyncResponse({
    required this.success,
    required this.serverTimestamp,
    required this.clientApplied,
    required this.serverRecords,
    required this.conflicts,
    this.message,
  });

  /// 从 JSON 构造
  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      success: json['success'] as bool,
      serverTimestamp: json['server_timestamp'] as int,
      clientApplied: json['client_applied'] as int,
      serverRecords: json['server_records'] != null
          ? (json['server_records'] as List)
              .map((r) => SyncRecord.fromJson(r as Map<String, dynamic>))
              .toList()
          : [],
      conflicts: json['conflicts'] != null
          ? (json['conflicts'] as List)
              .map((c) => ConflictInfo.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      message: json['message'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'server_timestamp': serverTimestamp,
      'client_applied': clientApplied,
      'server_records': SyncRecord.listToJson(serverRecords),
      'conflicts': conflicts.map((c) => c.toJson()).toList(),
      'message': message,
    };
  }
}

/// 实体类型常量
class EntityTypes {
  static const String todo = 'todo';
  static const String focusRecord = 'focus_record';
  static const String habit = 'habit';
  static const String habitLog = 'habit_log';
  static const String tag = 'tag';
  static const String tagRelation = 'tag_relation';

  static const List<String> all = [
    todo,
    focusRecord,
    habit,
    habitLog,
    tag,
    tagRelation,
  ];
}
