import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sample/music_track.dart';
import 'music_cache_manager.dart';

enum MusicPlaybackMode { listLoop, shuffle, radio }

class BackgroundMusicProvider extends ChangeNotifier {
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  bool _isDisposed = false;

  final List<MusicTrack> _playlist = [];
  List<MusicTrack> _defaultTracks = [];
  List<MusicTrack> _radioTracks = [];
  int _currentTrackIndex = -1;
  MusicPlaybackMode _playbackMode = MusicPlaybackMode.listLoop;
  bool _isBackgroundMusicPlaying = false;
  double _backgroundMusicVolume = 0.5;
  bool _isLoadingMusic = false;

  // Cache manager (委托缓存操作)
  final MusicCacheManager _cacheManager = MusicCacheManager();

  // Error handling state
  MusicErrorType _lastErrorType = MusicErrorType.unknownError;
  String _lastErrorMessage = '';
  MusicTrack? _errorTrack;
  DateTime? _errorTime;
  int _retryCount = 0;
  static const int _kMaxRetries = 2; // 最多重试次数

  // Public accessors for settings/UI
  int get cacheMaxBytes => _cacheManager.cacheMaxBytes;
  Future<int> getCacheSize() async => _cacheManager.calculateCacheSize();

  // Getters
  List<MusicTrack> get playlist => _playlist;
  List<MusicTrack> get defaultTracks => _defaultTracks;
  List<MusicTrack> get radioTracks => _radioTracks;
  MusicTrack? get currentTrack {
    if (_activeQueue.isNotEmpty &&
        _currentTrackIndex >= 0 &&
        _currentTrackIndex < _activeQueue.length) {
      return _activeQueue[_currentTrackIndex];
    }
    if (_currentTrackIndex >= 0 && _currentTrackIndex < _playlist.length) {
      return _playlist[_currentTrackIndex];
    }
    return null;
  }

  MusicPlaybackMode get playbackMode => _playbackMode;
  bool get isBackgroundMusicPlaying => _isBackgroundMusicPlaying;
  double get backgroundMusicVolume => _backgroundMusicVolume;
  bool get isLoadingMusic => _isLoadingMusic;

  // Error state accessors for UI
  MusicErrorType get errorType => _lastErrorType;
  String get errorMessage => _lastErrorMessage;
  MusicTrack? get errorTrack => _errorTrack;
  DateTime? get errorTime => _errorTime;
  bool get hasError => _lastErrorType != MusicErrorType.unknownError;
  bool get canRetry => _retryCount < _kMaxRetries;
  RecoveryAction get recoveryAction => _getRecoveryAction();

  Stream<Duration> get backgroundMusicPositionStream =>
      _backgroundMusicPlayer.positionStream;
  Stream<Duration?> get backgroundMusicDurationStream =>
      _backgroundMusicPlayer.durationStream;
  Stream<ProcessingState> get backgroundMusicProcessingStateStream =>
      _backgroundMusicPlayer.processingStateStream;

  BackgroundMusicProvider() {
    _loadSettings();
    _initBackgroundMusicPlayer();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (_) {}
    }
  }

  /// 设置当前错误状态
  void _setError(MusicErrorType type, String message, [MusicTrack? track]) {
    _lastErrorType = type;
    _lastErrorMessage = message;
    _errorTrack = track;
    _errorTime = DateTime.now();
    _retryCount = 0;
    debugPrint('MusicError [$type]: $message${track != null ? ' - ${track.title}' : ''}');
    _safeNotify();
  }

  /// 清除错误状态
  void _clearError() {
    if (_lastErrorType != MusicErrorType.unknownError) {
      _lastErrorType = MusicErrorType.unknownError;
      _lastErrorMessage = '';
      _errorTrack = null;
      _errorTime = null;
      _retryCount = 0;
      _safeNotify();
    }
  }

  /// 清除错误状态（公开 API）
  void clearError() => _clearError();

  /// 获取恢复操作建议
  RecoveryAction _getRecoveryAction() {
    switch (_lastErrorType) {
      case MusicErrorType.networkError:
        return _retryCount < _kMaxRetries ? RecoveryAction.retry : RecoveryAction.checkNetwork;
      case MusicErrorType.fileError:
        if (_errorTrack?.isLocal == true) {
          return RecoveryAction.importAgain;
        }
        return RecoveryAction.redownload;
      case MusicErrorType.cacheError:
        return RecoveryAction.clearCache;
      case MusicErrorType.audioError:
        return RecoveryAction.redownload;
      case MusicErrorType.playbackError:
        return RecoveryAction.retry;
      case MusicErrorType.unknownError:
        return RecoveryAction.none;
    }
  }

  /// 处理网络错误
  void _handleNetworkError(dynamic error, MusicTrack? track) {
    String message;
    if (error is TimeoutException) {
      message = '网络连接超时，请检查网络设置';
    } else if (error is SocketException) {
      message = '无法连接到服务器，请检查网络连接';
    } else if (error is http.ClientException) {
      message = '网络请求失败：${error.message}';
    } else if (error.toString().contains('Failed host lookup')) {
      message = '无法解析域名，请检查网络连接';
    } else {
      message = '网络错误：${error.toString()}';
    }
    _setError(MusicErrorType.networkError, message, track);
  }

  /// 处理文件错误
  void _handleFileError(dynamic error, MusicTrack? track) {
    String message;
    final errorStr = error.toString();
    if (errorStr.contains('not found') || errorStr.contains('ENOENT')) {
      message = '文件不存在，可能已被移动或删除';
    } else if (errorStr.contains('Permission') || errorStr.contains('access')) {
      message = '没有文件访问权限，请检查应用权限设置';
    } else if (errorStr.contains('locked') || errorStr.contains('busy')) {
      message = '文件被其他程序占用，请关闭其他应用后重试';
    } else {
      message = '文件访问错误：${error.toString()}';
    }
    _setError(MusicErrorType.fileError, message, track);
  }

  /// 处理音频错误
  void _handleAudioError(dynamic error, MusicTrack? track) {
    String message;
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('format') || errorStr.contains('codec')) {
      message = '音频格式不支持，无法播放此文件';
    } else if (errorStr.contains('duration')) {
      message = '无法获取音频时长信息';
    } else {
      message = '音频播放错误：${error.toString()}';
    }
    _setError(MusicErrorType.audioError, message, track);
  }

  /// 处理播放运行时错误
  void _handlePlaybackError(dynamic error, MusicTrack? track) {
    final message = '播放出错：${error.toString()}';
    _setError(MusicErrorType.playbackError, message, track);
  }

  /// 手动清除错误并重试（带指数退避）
  Future<void> retryAfterError() async {
    if (!canRetry || _errorTrack == null) return;
    _retryCount++;
    // 指数退避：500ms, 1s, 2s...
    final delay = Duration(milliseconds: 500 * (1 << _retryCount));
    await Future.delayed(delay);
    await playTrack(_errorTrack!);
  }

  void _initBackgroundMusicPlayer() {
    _playerStateSubscription = _backgroundMusicPlayer.playerStateStream.listen((
      state,
    ) {
      _isBackgroundMusicPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onTrackFinished();
      }
      // 清除之前的错误状态（成功播放时）
      if (state.processingState == ProcessingState.ready && hasError) {
        _clearError();
      }
      notifyListeners();
    });

    // 监听播放事件以捕获运行时错误
    _playbackEventSubscription = _backgroundMusicPlayer.playbackEventStream.listen(
      (event) {
        // just_audio 使用 playing 状态和 processingState 来判断播放状态
        // 错误通常通过 playerStateStream 的 error 属性获取
      },
      onError: (error) {
        _handlePlaybackError(error, currentTrack);
      },
    );
  }

  void _onTrackFinished() {
    if (_playbackMode == MusicPlaybackMode.listLoop ||
        _playbackMode == MusicPlaybackMode.shuffle) {
      playNext();
    } else {
      // Radio mode
      playNext();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _backgroundMusicVolume =
        prefs.getDouble('pomodoro_backgroundMusicVolume') ?? 0.5;
    await _backgroundMusicPlayer.setVolume(_backgroundMusicVolume);

    int? modeIndex = prefs.getInt('pomodoro_playbackMode');
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < MusicPlaybackMode.values.length) {
      _playbackMode = MusicPlaybackMode.values[modeIndex];
    }

    // Load imported tracks
    final importedPaths =
        prefs.getStringList('pomodoro_importedMusicPaths') ?? [];
    for (var path in importedPaths) {
      final fileName = path.contains('/')
          ? path.split('/').last
          : path.contains('\\')
          ? path.split('\\').last
          : path;
      _playlist.add(
        MusicTrack(
          id: path,
          title: fileName,
          artist: 'Local Import',
          sourceUrl: path,
          isLocal: true,
          localPath: path,
        ),
      );
    }

    fetchDefaultTracks();
    await fetchDefaultTracks();
    await fetchRadioTracks();

    // Load cache settings and cached track map
    try {
      await _cacheManager.loadCacheSettings();

      // Validate cached files and apply to defaultTracks
      final toRemove = <String>[];
      for (final entry in _cacheManager.cachedTrackMap.entries) {
        if (kIsWeb) {
          // No local file system on web — remove mapping.
          toRemove.add(entry.key);
          continue;
        }
        final file = File(entry.value);
        final isValid = await _cacheManager.isValidCacheFile(file);
        if (isValid && await file.exists()) {
          final idx = _defaultTracks.indexWhere((t) => t.id == entry.key);
          if (idx != -1) {
            _defaultTracks[idx] = _defaultTracks[idx].copyWith(
              isLocal: true,
              localPath: entry.value,
            );
          }
        } else {
          // 缓存文件无效或不存在，尝试重新下载
          MusicTrack? missingTrack;
          final defIdx = _defaultTracks.indexWhere((t) => t.id == entry.key);
          if (defIdx != -1) {
            missingTrack = _defaultTracks[defIdx];
          } else {
            final rIdx = _radioTracks.indexWhere((t) => t.id == entry.key);
            if (rIdx != -1) missingTrack = _radioTracks[rIdx];
          }

          if (missingTrack != null) {
            // 清理无效缓存记录
            toRemove.add(entry.key);
            // Schedule an immediate re-download without blocking settings load.
            Future.microtask(() async {
              try {
                await downloadTrack(missingTrack!);
              } catch (e) {
                debugPrint(
                  'Failed to re-download missing cached track ${entry.key}: $e',
                );
              }
            });
          } else {
            toRemove.add(entry.key);
          }
        }
      }
      for (final k in toRemove) {
        _cacheManager.cachedTrackMap.remove(k);
      }
      await _cacheManager.persistCacheMap(prefs);
    } catch (e) {
      debugPrint('Error loading cache settings: $e');
    }

    // Restore last playback state (last queue + index/track id)
    await _restorePlaybackState(prefs);
  }

  Future<void> fetchDefaultTracks() async {
    // Example URL - replace with your actual GitHub raw URL
    // const url =
    //     'https://raw.githubusercontent.com/ChenXu233/ToDoTimeSquare/main/assets/music/default_playlist.json';
    try {
      // final response = await http.get(Uri.parse(url));
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   _defaultTracks = data.map((e) => MusicTrack.fromJson(e)).toList();
      //   notifyListeners();
      // }

      // Mock data
      _defaultTracks = [
        MusicTrack(
          id: 'def_1',
          title: 'Frozen Waters',
          artist: 'hoogway / softy',
          sourceUrl:
              'https://fastapi-python-163music.vercel.app/gd/redirect?id=1866350557',
        ),
        MusicTrack(
          id: 'def_2',
          title: "It's Okay",
          artist: 'Ayzic / Project AER',
          sourceUrl:
              'https://fastapi-python-163music.vercel.app/gd/redirect?id=1840791849',
        ),
        MusicTrack(
          id: 'def_3',
          title: 'Hiraeth',
          artist: 'Bcalm / Banks',
          sourceUrl:
              'https://fastapi-python-163music.vercel.app/gd/redirect?id=1902794853',
        ),
        MusicTrack(
          id: "def_4",
          title: "Cascade",
          artist: "kinissue / Ayzic",
          sourceUrl:
              'https://fastapi-python-163music.vercel.app/gd/redirect?id=1855900632',
        ),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching default tracks: $e');
    }
  }

  Future<void> fetchRadioTracks() async {
    // Example URL - replace with your actual GitHub raw URL
    const url =
        'https://raw.githubusercontent.com/ChenXu233/ToDoTimeSquare/music-radio/radio_playlist.json';
    const int maxRetries = 2;
    const Duration timeout = Duration(seconds: 10);
    int attempt = 0;

    _isLoadingMusic = true;
    _safeNotify();

    while (true) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(timeout);
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _radioTracks = data.map((e) {
            final map = e as Map<String, dynamic>;
            map['isRadio'] = true;
            return MusicTrack.fromJson(map);
          }).toList();
          _isLoadingMusic = false;
          _safeNotify();
          return;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        debugPrint('Error fetching radio tracks (attempt $attempt): $e');
        if (attempt > maxRetries) {
          _isLoadingMusic = false;
          _safeNotify();
          return;
        }
        // Exponential backoff before retrying
        final backoff = Duration(seconds: 2 * attempt);
        await Future.delayed(backoff);
      }
    }
  }

  Future<void> importMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      // On non-web platforms, FilePicker returns file system paths.
      final newPaths = result.paths.whereType<String>().toList();
      for (var path in newPaths) {
        if (!_playlist.any((t) => t.localPath == path)) {
          final fileName = path.contains('/')
              ? path.split('/').last
              : path.contains('\\')
              ? path.split('\\').last
              : path;
          _playlist.add(
            MusicTrack(
              id: path,
              title: fileName,
              artist: 'Local Import',
              sourceUrl: path,
              isLocal: true,
              localPath: path,
            ),
          );
        }
      }

      // On web, FilePicker may not provide paths. We deliberately skip adding
      // web-picked files to the playlist here to avoid requiring Blob URL handling.
      // If web import is desired, implement Blob -> Object URL logic.
      _saveImportedTracks();
      _safeNotify();
    }
  }

  Future<void> _saveImportedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = _playlist
          .where((t) => t.isLocal && t.localPath != null)
          .map((t) => t.localPath!)
          .toList();
      await prefs.setStringList('pomodoro_importedMusicPaths', paths);
    } catch (e) {
      debugPrint('Error saving imported tracks: $e');
    }
  }

  Future<void> removeTrack(MusicTrack track) async {
    if (track.isLocal) {
      _playlist.removeWhere((t) => t.id == track.id);
      _saveImportedTracks();
    } else {
      if (track.localPath != null) {
        if (!kIsWeb) {
          try {
            final file = File(track.localPath!);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint("Error deleting file: $e");
          }
        }
        final index = _defaultTracks.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          _defaultTracks[index] = _defaultTracks[index].copyWith(
            localPath: null,
            isLocal: false,
          );
        }
      }
    }

    if (currentTrack?.id == track.id) {
      await _backgroundMusicPlayer.stop();
      _currentTrackIndex = -1;
    }
    await _savePlaybackState();
    _safeNotify();
  }

  Future<void> downloadTrack(MusicTrack track) async {
    if (track.isLocal || track.localPath != null) return;
    if (kIsWeb) {
      debugPrint(
        'downloadTrack: skipping cache/download on web for ${track.id}',
      );
      return;
    }

    _isLoadingMusic = true;
    _safeNotify();

    try {
      final success = await _cacheManager.downloadTrack(track);
      if (success) {
        final index = _defaultTracks.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          final cachedPath = _cacheManager.cachedTrackMap[track.id];
          if (cachedPath != null) {
            _defaultTracks[index] = _defaultTracks[index].copyWith(
              isLocal: true,
              localPath: cachedPath,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Download error: $e");
    } finally {
      _isLoadingMusic = false;
      _safeNotify();
    }
  }

  // --- 缓存操作委托给 MusicCacheManager ---

  // 内部使用：直接委托给缓存管理器
  Future<File> _getCachedFile(MusicTrack track) => _cacheManager.getCachedFile(track);
  Future<bool> _isValidCacheFile(File file) => _cacheManager.isValidCacheFile(file);
  Future<void> _persistCachedTrackMap([SharedPreferences? prefs]) =>
      _cacheManager.persistCacheMap(prefs);
  Future<void> _enforceCacheSize() => _cacheManager.enforceCacheSize();

  // 公开 API：委托给缓存管理器
  Future<void> setCacheMaxBytes(int bytes) async =>
      await _cacheManager.setCacheMaxBytes(bytes);

  Future<void> clearCache() async {
    await _cacheManager.clearCache();
    // Also clear local flags from defaultTracks
    for (int i = 0; i < _defaultTracks.length; i++) {
      _defaultTracks[i] = _defaultTracks[i].copyWith(
        isLocal: false,
        localPath: null,
      );
    }
  }

  Future<void> playTrack(MusicTrack track) async {
    // 清除之前的错误状态
    _clearError();

    // If playing from default/radio lists, we need to handle the playlist context.
    List<MusicTrack> targetQueue;
    if (_playlist.any((t) => t.id == track.id)) {
      targetQueue = _playlist;
    } else if (_defaultTracks.any((t) => t.id == track.id)) {
      targetQueue = _defaultTracks;
    } else if (_radioTracks.any((t) => t.id == track.id)) {
      targetQueue = _radioTracks;
    } else {
      // Fallback
      targetQueue = _playlist;
    }

    _activeQueue = targetQueue;
    _currentTrackIndex = _activeQueue.indexWhere((t) => t.id == track.id);

    try {
      // Prefer cached/local file to avoid network requests every time.
      if (track.isLocal || track.localPath != null) {
        final localPath = track.localPath ?? track.sourceUrl;
        await _playFromLocalFile(track, localPath);
      } else {
        if (kIsWeb) {
          // No local cache on web — stream directly.
          await _playFromNetwork(track, track.sourceUrl);
        } else {
          final cachedFile = await _getCachedFile(track);
          if (await cachedFile.exists()) {
            // 验证缓存文件完整性
            if (await _isValidCacheFile(cachedFile)) {
              await _playFromLocalFile(track, cachedFile.path);
            } else {
              // 缓存损坏，删除并重新下载
              debugPrint('Cache file corrupted, re-downloading...');
              try {
                await cachedFile.delete();
              } catch (_) {
                // 忽略删除错误，继续尝试重新下载
              }
              await _downloadAndPlay(track);
            }
          } else {
            await _downloadAndPlay(track);
          }
        }
      }

      await _backgroundMusicPlayer.play();
      await _savePlaybackState();
      _clearError();
      _safeNotify();
    } catch (e, st) {
      // 分类处理错误
      _classifyAndHandleError(e, st, track);
    }
  }

  /// 从本地文件播放
  Future<void> _playFromLocalFile(MusicTrack track, String path) async {
    try {
      if (kIsWeb) {
        // Web cannot play local file paths; fall back to streaming.
        await _playFromNetwork(track, track.sourceUrl);
      } else {
        await _backgroundMusicPlayer.setAudioSource(
          AudioSource.file(path),
        );
      }
    } catch (e, st) {
      // 文件错误，尝试回退到网络播放
      debugPrint('Local file error: $e\n$st');
      if (!kIsWeb && track.localPath != null && track.sourceUrl.isNotEmpty) {
        try {
          await _playFromNetwork(track, track.sourceUrl);
          return;
        } catch (_) {
          // 网络播放也失败，抛出原错误
        }
      }
      rethrow;
    }
  }

  /// 从网络播放
  Future<void> _playFromNetwork(MusicTrack track, String url) async {
    try {
      await _backgroundMusicPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
      );
    } catch (e) {
      _handleNetworkError(e, track);
      rethrow;
    }
  }

  /// 下载并播放（非缓存情况）
  Future<void> _downloadAndPlay(MusicTrack track) async {
    _isLoadingMusic = true;
    _safeNotify();

    try {
      final cachedFile = await _getCachedFile(track);
      final response = await http.get(Uri.parse(track.sourceUrl)).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode == 200) {
        await cachedFile.parent.create(recursive: true);
        await cachedFile.writeAsBytes(response.bodyBytes);

        // 验证下载的文件
        if (response.bodyBytes.length < 1024) {
          throw Exception('Downloaded file too small, possible corruption');
        }

        if (kIsWeb) {
          await _playFromNetwork(track, track.sourceUrl);
        } else {
          await _playFromLocalFile(track, cachedFile.path);
        }

        // update defaultTracks entry if applicable
        final index = _defaultTracks.indexWhere(
          (t) => t.id == track.id,
        );
        if (index != -1) {
          _defaultTracks[index] = _defaultTracks[index].copyWith(
            isLocal: true,
            localPath: cachedFile.path,
          );
        }

        // persist cache map and enforce size limit
        _cacheManager.cachedTrackMap[track.id] = cachedFile.path;
        await _persistCachedTrackMap();
        await _enforceCacheSize();
      } else {
        // 下载失败，回退到流式播放
        debugPrint('Download failed with status ${response.statusCode}');
        await _playFromNetwork(track, track.sourceUrl);
      }
    } catch (e, st) {
      debugPrint('Download error: $e\n$st');
      // 网络错误，尝试直接流式播放
      if (e is TimeoutException || e is SocketException || e is http.ClientException) {
        try {
          await _playFromNetwork(track, track.sourceUrl);
          return;
        } catch (_) {}
      }
      rethrow;
    } finally {
      _isLoadingMusic = false;
      _safeNotify();
    }
  }

  /// 分类并处理错误
  void _classifyAndHandleError(dynamic error, StackTrace st, MusicTrack track) {
    final errorStr = error.toString().toLowerCase();

    // 网络错误
    if (error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException ||
        errorStr.contains('failed host') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      _handleNetworkError(error, track);
      return;
    }

    // 文件错误
    if (error is FileSystemException ||
        errorStr.contains('not found') ||
        errorStr.contains('permission') ||
        errorStr.contains('enoent') ||
        errorStr.contains('access denied')) {
      _handleFileError(error, track);
      return;
    }

    // 音频错误
    if (errorStr.contains('format') ||
        errorStr.contains('codec') ||
        errorStr.contains('audio') ||
        errorStr.contains('duration')) {
      _handleAudioError(error, track);
      return;
    }

    // 未知错误
    _setError(
      MusicErrorType.unknownError,
      '播放出错：${error.toString()}',
      track,
    );
    debugPrint('Unknown error playing track: $error\n$st');
  }

  List<MusicTrack> _activeQueue = [];
  // persisted playback state keys
  static const _kLastTrackId = 'pomodoro_lastTrackId';
  static const _kLastQueue =
      'pomodoro_lastQueue'; // values: 'local','default','radio'
  static const _kLastTrackIndex = 'pomodoro_lastTrackIndex';

  Future<void> playNext() async {
    if (_activeQueue.isEmpty) return;

    int nextIndex;
    if (_playbackMode == MusicPlaybackMode.shuffle) {
      nextIndex = Random().nextInt(_activeQueue.length);
    } else {
      nextIndex = (_currentTrackIndex + 1) % _activeQueue.length;
    }

    // If list loop is off (e.g. single play), we might stop.
    // But usually "List Loop" means loop the list.
    // If we want "No Loop", we stop at end.
    // Assuming "List Loop" is the default behavior for non-shuffle.

    _currentTrackIndex = nextIndex;
    await playTrack(_activeQueue[_currentTrackIndex]);
  }

  Future<void> _savePlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final track = currentTrack;
      if (track != null) {
        await prefs.setString(_kLastTrackId, track.id);
      } else {
        await prefs.remove(_kLastTrackId);
      }

      String queueName = 'local';
      if (_activeQueue == _playlist) {
        queueName = 'local';
      } else if (_activeQueue == _defaultTracks) {
        queueName = 'default';
      } else if (_activeQueue == _radioTracks) {
        queueName = 'radio';
      }
      await prefs.setString(_kLastQueue, queueName);

      await prefs.setInt(_kLastTrackIndex, _currentTrackIndex);
    } catch (e) {
      debugPrint('Error saving playback state: $e');
    }
  }

  Future<void> _restorePlaybackState(SharedPreferences prefs) async {
    try {
      final lastQueue = prefs.getString(_kLastQueue);
      final lastIndex = prefs.getInt(_kLastTrackIndex);
      final lastTrackId = prefs.getString(_kLastTrackId);

      if (lastQueue == 'local' && _playlist.isNotEmpty) {
        _activeQueue = _playlist;
      } else if (lastQueue == 'default' && _defaultTracks.isNotEmpty) {
        _activeQueue = _defaultTracks;
      } else if (lastQueue == 'radio' && _radioTracks.isNotEmpty) {
        _activeQueue = _radioTracks;
      }

      if (lastTrackId != null && _activeQueue.isNotEmpty) {
        final idx = _activeQueue.indexWhere((t) => t.id == lastTrackId);
        if (idx != -1) {
          _currentTrackIndex = idx;
          return;
        }
      }

      if (lastIndex != null && _activeQueue.isNotEmpty) {
        if (lastIndex >= 0 && lastIndex < _activeQueue.length) {
          _currentTrackIndex = lastIndex;
        }
      }
    } catch (e) {
      debugPrint('Error restoring playback state: $e');
    }
  }

  Future<void> playPrevious() async {
    if (_activeQueue.isEmpty) return;

    int prevIndex;
    if (_playbackMode == MusicPlaybackMode.shuffle) {
      prevIndex = Random().nextInt(_activeQueue.length);
    } else {
      prevIndex =
          (_currentTrackIndex - 1 + _activeQueue.length) % _activeQueue.length;
    }

    _currentTrackIndex = prevIndex;
    await playTrack(_activeQueue[_currentTrackIndex]);
  }

  Future<void> togglePlaybackMode() async {
    final nextIndex =
        (_playbackMode.index + 1) % MusicPlaybackMode.values.length;
    _playbackMode = MusicPlaybackMode.values[nextIndex];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_playbackMode', _playbackMode.index);

    _safeNotify();
  }

  Future<void> toggleBackgroundMusic() async {
    if (_backgroundMusicPlayer.playing) {
      await _backgroundMusicPlayer.pause();
    } else {
      await _backgroundMusicPlayer.play();
    }
  }

  Future<void> pauseBackgroundMusic() async {
    if (_backgroundMusicPlayer.playing) {
      await _backgroundMusicPlayer.pause();
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (_backgroundMusicPlayer.playing) return;

    // If there's already a current track, just resume it.
    if (currentTrack != null) {
      await _backgroundMusicPlayer.play();
      return;
    }

    // No current track: choose the active queue if user selected it,
    // otherwise prefer local imported playlist, then defaults, then radio.
    if (_activeQueue.isEmpty) {
      if (_playlist.isNotEmpty) {
        _activeQueue = _playlist;
      } else if (_defaultTracks.isNotEmpty) {
        _activeQueue = _defaultTracks;
      } else if (_radioTracks.isNotEmpty) {
        _activeQueue = _radioTracks;
      } else {
        return;
      }
      _currentTrackIndex = 0;
    } else {
      if (_currentTrackIndex < 0 || _currentTrackIndex >= _activeQueue.length) {
        _currentTrackIndex = 0;
      }
    }

    // Start playing the selected track (which will set the audio source).
    await playTrack(_activeQueue[_currentTrackIndex]);
  }

  Future<void> setBackgroundMusicVolume(double volume) async {
    _backgroundMusicVolume = volume;
    await _backgroundMusicPlayer.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pomodoro_backgroundMusicVolume', volume);
    _safeNotify();
  }

  Future<void> seekTo(Duration position) async {
    await _backgroundMusicPlayer.seek(position);
  }

  @override
  void dispose() {
    // Mark disposed to prevent notifyListeners calls from async work.
    _isDisposed = true;
    // Cancel subscriptions first to avoid callbacks after dispose.
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _playbackEventSubscription?.cancel();
    _playbackEventSubscription = null;
    _backgroundMusicPlayer.dispose();
    super.dispose();
  }
}
