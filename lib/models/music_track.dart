/// 音乐播放错误类型分类
enum MusicErrorType {
  networkError, // 网络问题（离线、超时、服务器错误）
  fileError, // 文件问题（不存在、权限、损坏）
  audioError, // 音频播放错误（格式不支持、编解码）
  playbackError, // 播放运行时错误
  cacheError, // 缓存问题
  unknownError, // 未知错误
}

/// 恢复操作建议
enum RecoveryAction {
  none, // 无需操作
  retry, // 重试播放
  redownload, // 重新下载
  clearCache, // 清除缓存
  importAgain, // 重新导入
  checkNetwork, // 检查网络
}

class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String sourceUrl; // URL for remote, path for local
  final bool isLocal;
  final bool isRadio;
  String? localPath; // Path if downloaded or imported

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceUrl,
    this.isLocal = false,
    this.isRadio = false,
    this.localPath,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      sourceUrl: json['sourceUrl'] as String,
      isLocal: json['isLocal'] as bool? ?? false,
      isRadio: json['isRadio'] as bool? ?? false,
      localPath: json['localPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'sourceUrl': sourceUrl,
      'isLocal': isLocal,
      'isRadio': isRadio,
      'localPath': localPath,
    };
  }
  
  MusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? sourceUrl,
    bool? isLocal,
    bool? isRadio,
    String? localPath,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isLocal: isLocal ?? this.isLocal,
      isRadio: isRadio ?? this.isRadio,
      localPath: localPath ?? this.localPath,
    );
  }
}
