import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/music_track.dart';

enum MusicPlaybackMode { listLoop, shuffle, radio }

class BackgroundMusicProvider extends ChangeNotifier {
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _isDisposed = false;
  
  final List<MusicTrack> _playlist = [];
  List<MusicTrack> _defaultTracks = [];
  List<MusicTrack> _radioTracks = [];
  int _currentTrackIndex = -1;
  MusicPlaybackMode _playbackMode = MusicPlaybackMode.listLoop;
  bool _isBackgroundMusicPlaying = false;
  double _backgroundMusicVolume = 0.5;
  bool _isLoadingMusic = false;
  // Cache settings
  int _cacheMaxBytes = 200 * 1024 * 1024; // default 200 MB
  final Map<String, String> _cachedTrackMap = {}; // trackId -> localPath

  // Public accessors for settings/UI
  int get cacheMaxBytes => _cacheMaxBytes;
  Future<int> getCacheSize() async => await _calculateCacheSize();


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

  void _initBackgroundMusicPlayer() {
    _playerStateSubscription = _backgroundMusicPlayer.playerStateStream.listen((
      state,
    ) {
      _isBackgroundMusicPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onTrackFinished();
      }
      notifyListeners();
    });
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
    if (modeIndex != null && modeIndex >= 0 && modeIndex < MusicPlaybackMode.values.length) {
      _playbackMode = MusicPlaybackMode.values[modeIndex];
    }

    // Load imported tracks
    final importedPaths = prefs.getStringList('pomodoro_importedMusicPaths') ?? [];
    for (var path in importedPaths) {
      final fileName = path.split(Platform.pathSeparator).last;
      _playlist.add(MusicTrack(
        id: path,
        title: fileName,
        artist: 'Local Import',
        sourceUrl: path,
        isLocal: true,
        localPath: path,
      ));
    }

    fetchDefaultTracks();
    await fetchDefaultTracks();
    await fetchRadioTracks();

    // Load cache settings and cached track map
    try {
      final maxBytes = prefs.getInt(_kCacheMaxBytesKey);
      if (maxBytes != null && maxBytes > 0) _cacheMaxBytes = maxBytes;

      final mapJson = prefs.getString(_kCachedTrackMapKey);
      if (mapJson != null && mapJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(mapJson);
        decoded.forEach((key, value) {
          if (value is String) _cachedTrackMap[key] = value;
        });
      }

      // Validate cached files and apply to defaultTracks
      final toRemove = <String>[];
      for (final entry in _cachedTrackMap.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          final idx = _defaultTracks.indexWhere((t) => t.id == entry.key);
          if (idx != -1) {
            _defaultTracks[idx] = _defaultTracks[idx].copyWith(
              isLocal: true,
              localPath: entry.value,
            );
          }
        } else {
          // Try to find the track in default or radio lists and re-download immediately.
          MusicTrack? missingTrack;
          final defIdx = _defaultTracks.indexWhere((t) => t.id == entry.key);
          if (defIdx != -1)
            missingTrack = _defaultTracks[defIdx];
          else {
            final rIdx = _radioTracks.indexWhere((t) => t.id == entry.key);
            if (rIdx != -1) missingTrack = _radioTracks[rIdx];
          }

          if (missingTrack != null) {
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
      for (final k in toRemove) _cachedTrackMap.remove(k);
      await _persistCachedTrackMap(prefs);
    } catch (e) {
      debugPrint('Error loading cache settings: $e');
    }

    // Restore last playback state (last queue + index/track id)
    await _restorePlaybackState(prefs);
  }

  Future<void> fetchDefaultTracks() async {
    // Example URL - replace with your actual GitHub raw URL
    const url = 'https://raw.githubusercontent.com/ChenXu233/ToDoTimeSquare/main/assets/music/default_playlist.json';
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
        )
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
      final newPaths = result.paths.whereType<String>().toList();
      for (var path in newPaths) {
        if (!_playlist.any((t) => t.localPath == path)) {
          final fileName = path.split(Platform.pathSeparator).last;
          _playlist.add(MusicTrack(
            id: path,
            title: fileName,
            artist: 'Local Import',
            sourceUrl: path,
            isLocal: true,
            localPath: path,
          ));
        }
      }
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
        try {
          final file = File(track.localPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint("Error deleting file: $e");
        }
        final index = _defaultTracks.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          _defaultTracks[index] = _defaultTracks[index].copyWith(localPath: null, isLocal: false);
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
    
    _isLoadingMusic = true;
    _safeNotify();

    try {
      final file = await _getCachedFile(track);

      // If already cached, mark as local and return
      if (await file.exists()) {
        final index = _defaultTracks.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          _defaultTracks[index] = _defaultTracks[index].copyWith(
            isLocal: true,
            localPath: file.path,
          );
        }
        return;
      }

      final response = await http.get(Uri.parse(track.sourceUrl));
      if (response.statusCode == 200) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        final index = _defaultTracks.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          _defaultTracks[index] = _defaultTracks[index].copyWith(
            isLocal: true,
            localPath: file.path,
          );
        }
        // persist cache map and enforce size limit
        _cachedTrackMap[track.id] = file.path;
        await _persistCachedTrackMap();
        await _enforceCacheSize();
      }
    } catch (e) {
      debugPrint("Download error: $e");
    } finally {
      _isLoadingMusic = false;
      _safeNotify();
    }
  }

  // --- Cache helpers ---
  Future<Directory> _getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/music_cache');
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
    return cacheDir;
  }

  String _cachedFileNameForTrack(MusicTrack track) {
    // Use base64url of the sourceUrl so filename is unique and filesystem-safe
    final encoded = base64Url.encode(utf8.encode(track.sourceUrl));
    return 'cache_$encoded.mp3';
  }

  Future<File> _getCachedFile(MusicTrack track) async {
    final cacheDir = await _getCacheDir();
    final filename = _cachedFileNameForTrack(track);
    return File('${cacheDir.path}/$filename');
  }

  // --- Cache persistence & maintenance ---
  static const _kCacheMaxBytesKey = 'pomodoro_cacheMaxBytes';
  static const _kCachedTrackMapKey = 'pomodoro_cachedTrackMap';

  Future<void> _persistCachedTrackMap([SharedPreferences? prefs]) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setString(_kCachedTrackMapKey, json.encode(_cachedTrackMap));
      await p.setInt(_kCacheMaxBytesKey, _cacheMaxBytes);
    } catch (e) {
      debugPrint('Error persisting cached track map: $e');
    }
  }

  Future<int> _calculateCacheSize() async {
    try {
      final dir = await _getCacheDir();
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _enforceCacheSize() async {
    try {
      final maxBytes = _cacheMaxBytes;
      int total = await _calculateCacheSize();
      if (total <= maxBytes) return;

      final dir = await _getCacheDir();
      final files = <File>[];
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) files.add(entity);
      }

      // Sort by last modified ascending (oldest first)
      files.sort((a, b) {
        final am = a.lastModifiedSync();
        final bm = b.lastModifiedSync();
        return am.compareTo(bm);
      });

      for (final f in files) {
        if (total <= maxBytes) break;
        try {
          final len = await f.length();
          await f.delete();
          total -= len;
          // remove from cached map if present
          final entryKey = _cachedTrackMap.entries.firstWhere(
            (e) => e.value == f.path,
            orElse: () => const MapEntry('', ''),
          );
          if (entryKey.key.isNotEmpty) {
            _cachedTrackMap.remove(entryKey.key);
          }
        } catch (e) {}
      }

      await _persistCachedTrackMap();
    } catch (e) {
      debugPrint('Error enforcing cache size: $e');
    }
  }

  /// Set maximum cache size in bytes and enforce it immediately.
  Future<void> setCacheMaxBytes(int bytes) async {
    _cacheMaxBytes = bytes;
    await _persistCachedTrackMap();
    await _enforceCacheSize();
  }

  /// Clear entire music cache directory and cached mappings.
  Future<void> clearCache() async {
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          try {
            if (entity is File) await entity.delete();
            if (entity is Directory) await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
      _cachedTrackMap.clear();
      // remove localPath flags from defaultTracks
      for (int i = 0; i < _defaultTracks.length; i++) {
        _defaultTracks[i] = _defaultTracks[i].copyWith(
          isLocal: false,
          localPath: null,
        );
      }
      await _persistCachedTrackMap();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Future<void> playTrack(MusicTrack track) async {
    // If playing from default/radio lists, we need to handle the playlist context.
    // For now, if it's not in _playlist, we add it temporarily or just play it.
    // To support "List Loop" correctly, we need a concept of "Current Queue".
    // Let's simplify: 
    // If user clicks a track in Local, queue is Local.
    // If user clicks a track in Default, queue is Default.
    // If user clicks a track in Radio, queue is Radio.
    
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
    
    // If we switched queues, we might want to update _playlist to reflect current queue?
    // Or just keep track of "active list".
    // For simplicity, let's just update _playlist to be the active queue if it's not Local.
    // BUT wait, _playlist is "Local Imports".
    // Let's introduce `_activeQueue`.
    
    _activeQueue = targetQueue;
    _currentTrackIndex = _activeQueue.indexWhere((t) => t.id == track.id);

    try {
      // Prefer cached/local file to avoid network requests every time.
      if (track.isLocal || track.localPath != null) {
        final localPath = track.localPath ?? track.sourceUrl;
        await _backgroundMusicPlayer.setAudioSource(
          AudioSource.file(localPath),
        );
      } else {
        final cachedFile = await _getCachedFile(track);
        if (await cachedFile.exists()) {
          await _backgroundMusicPlayer.setAudioSource(
            AudioSource.file(cachedFile.path),
          );
        } else {
          // Not cached yet: download to cache then play from file to avoid subsequent network calls.
          _isLoadingMusic = true;
          _safeNotify();
          try {
            final response = await http.get(Uri.parse(track.sourceUrl));
            if (response.statusCode == 200) {
              await cachedFile.parent.create(recursive: true);
              await cachedFile.writeAsBytes(response.bodyBytes);
              await _backgroundMusicPlayer.setAudioSource(
                AudioSource.file(cachedFile.path),
              );
              // update defaultTracks entry if applicable
              final index = _defaultTracks.indexWhere((t) => t.id == track.id);
              if (index != -1) {
                _defaultTracks[index] = _defaultTracks[index].copyWith(
                  isLocal: true,
                  localPath: cachedFile.path,
                );
              }
              // persist cache map and enforce size limit
              _cachedTrackMap[track.id] = cachedFile.path;
              await _persistCachedTrackMap();
              await _enforceCacheSize();
            } else {
              // Fallback to streaming if download failed
              await _backgroundMusicPlayer.setAudioSource(
                AudioSource.uri(Uri.parse(track.sourceUrl)),
              );
            }
          } finally {
            _isLoadingMusic = false;
            _safeNotify();
          }
        }
      }
      
      await _backgroundMusicPlayer.play();
      await _savePlaybackState();
      _safeNotify();
    } catch (e) {
      debugPrint("Error playing track: $e");
    }
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
      } else if (_activeQueue == _defaultTracks)
        queueName = 'default';
      else if (_activeQueue == _radioTracks)
        queueName = 'radio';
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
       prevIndex = (_currentTrackIndex - 1 + _activeQueue.length) % _activeQueue.length;
    }
    
    _currentTrackIndex = prevIndex;
    await playTrack(_activeQueue[_currentTrackIndex]);
  }

  Future<void> togglePlaybackMode() async {
    final nextIndex = (_playbackMode.index + 1) % MusicPlaybackMode.values.length;
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
    _backgroundMusicPlayer.dispose();
    super.dispose();
  }
}
