import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../models/dtos/sync_dto.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';

// Web端下载数量阈值
const int _kWebDownloadThreshold = 1000;

class SyncSettingsProvider with ChangeNotifier {
  static const String _serverUrlKey = 'sync_server_url';
  static const String _autoSyncKey = 'sync_auto_sync';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _deviceIdKey = 'device_id';
  static const String _defaultServerUrl = 'http://localhost:8000';

  final String defaultServerUrl = _defaultServerUrl;

  String _serverUrl = _defaultServerUrl;
  bool _autoSync = false;
  bool _isSyncing = false;
  String? _lastSyncResult;
  String? _errorMessage;
  int _lastSyncTimestamp = 0;
  int _conflictCount = 0;
  List<ConflictInfo> _conflicts = [];
  String? _deviceId;
  bool _showLargeDataWarning = false;

  // Getters
  String get serverUrl => _serverUrl;
  bool get autoSync => _autoSync;
  bool get isSyncing => _isSyncing;
  String? get lastSyncResult => _lastSyncResult;
  String? get errorMessage => _errorMessage;
  int get lastSyncTimestamp => _lastSyncTimestamp;
  int get conflictCount => _conflictCount;
  List<ConflictInfo> get conflicts => _conflicts;
  String? get deviceId => _deviceId;
  bool get showLargeDataWarning => _showLargeDataWarning;

  // 格式化后的最后同步时间
  String? get lastSyncTimeFormatted {
    if (_lastSyncTimestamp == 0) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(_lastSyncTimestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 是否有未解决的冲突
  bool get hasConflicts => _conflictCount > 0;

  SyncSettingsProvider() {
    _loadSettings();
  }

  /// 加载保存的设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _serverUrl = prefs.getString(_serverUrlKey) ?? _defaultServerUrl;
      _autoSync = prefs.getBool(_autoSyncKey) ?? false;
      _lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey) ?? 0;
      _deviceId = prefs.getString(_deviceIdKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sync settings: $e');
    }
  }

  /// 更新服务器地址
  Future<void> setServerUrl(String url) async {
    if (url.isEmpty) {
      _errorMessage = 'Server URL cannot be empty';
      notifyListeners();
      return;
    }

    // 验证 URL 格式
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        _errorMessage = 'Please enter a valid URL (e.g., http://localhost:8000)';
        notifyListeners();
        return;
      }
    } catch (e) {
      _errorMessage = 'Invalid URL format';
      notifyListeners();
      return;
    }

    _serverUrl = url;
    _errorMessage = null;

    // 保存到 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);

    notifyListeners();
  }

  /// 设置同步中状态
  void setSyncing(bool syncing) {
    _isSyncing = syncing;
    if (!syncing) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// 设置同步结果
  void setSyncResult(String result) {
    _lastSyncResult = result;
    _errorMessage = null;
    notifyListeners();
  }

  /// 设置同步错误
  void setSyncError(String error) {
    _errorMessage = error;
    _lastSyncResult = null;
    notifyListeners();
  }

  /// 设置最后同步时间戳
  Future<void> setLastSyncTimestamp(int timestamp) async {
    _lastSyncTimestamp = timestamp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimestampKey, timestamp);
    notifyListeners();
  }

  /// 获取设备ID
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
    return _deviceId!;
  }

  /// 设置冲突数量
  void setConflictCount(int count) {
    _conflictCount = count;
    notifyListeners();
  }

  /// 设置冲突列表
  void setConflicts(List<ConflictInfo> conflicts) {
    _conflicts = conflicts;
    _conflictCount = conflicts.length;
    notifyListeners();
  }

  /// 清除冲突列表
  void clearConflicts() {
    _conflicts = [];
    _conflictCount = 0;
    notifyListeners();
  }

  /// 设置大量数据警告（Web端专用）
  void setLargeDataWarning(bool show) {
    _showLargeDataWarning = show;
    notifyListeners();
  }

  /// 清除大量数据警告
  void clearLargeDataWarning() {
    _showLargeDataWarning = false;
    notifyListeners();
  }

  /// 恢复同步设置为默认
  Future<void> resetSyncSettings() async {
    _serverUrl = _defaultServerUrl;
    _autoSync = false;
    _errorMessage = null;
    _lastSyncResult = null;
    _conflicts = [];
    _conflictCount = 0;

    // 保存默认设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, _defaultServerUrl);
    await prefs.setBool(_autoSyncKey, false);

    notifyListeners();
  }

  /// 设置自动同步
  Future<void> setAutoSync(bool value) async {
    _autoSync = value;

    // 保存到 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, value);

    notifyListeners();
  }

  /// 清空错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 重置同步时间戳（用于全量同步）
  Future<void> resetSyncTimestamp() async {
    _lastSyncTimestamp = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimestampKey, 0);
    _lastSyncResult = '已重置，将执行全量同步';
    notifyListeners();
  }

  /// 获取完整的基础 URL
  String get baseUrl => _serverUrl;

  /// 开始同步（带进度显示）
  Future<void> startSync(BuildContext context) async {
    final syncService = context.read<SyncService>();
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn || authProvider.accessToken == null) {
      setSyncError('请先登录后再同步');
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    _lastSyncResult = null;
    _showLargeDataWarning = false;
    notifyListeners();

    try {
      final response = await syncService.sync(authProvider.accessToken!);

      if (response.success) {
        await setLastSyncTimestamp(response.serverTimestamp);

        // Web端检测大量数据警告
        if (kIsWeb && response.serverRecords.length > _kWebDownloadThreshold) {
          _showLargeDataWarning = true;
          notifyListeners();
        }

        if (response.conflicts.isEmpty) {
          setSyncResult('同步成功');
        } else {
          setConflicts(response.conflicts);
          setSyncResult('同步完成，${response.conflicts.length} 个冲突待解决');
        }
      } else {
        setSyncError(response.message ?? '同步失败');
      }
    } catch (e) {
      setSyncError(e.toString().replaceAll('SyncException: ', ''));
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
