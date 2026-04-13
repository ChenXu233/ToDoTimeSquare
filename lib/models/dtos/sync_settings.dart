/// 同步配置（纯数据类，不依赖 Provider）
class SyncSettings {
  /// 服务器基础 URL
  final String baseUrl;

  /// 默认服务器地址
  static const String defaultServerUrl = 'http://localhost:8000';

  const SyncSettings({
    this.baseUrl = defaultServerUrl,
  });
}
