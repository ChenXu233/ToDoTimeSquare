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
  
  List<MusicTrack> _playlist = [];
  List<MusicTrack> _defaultTracks = [];
  List<MusicTrack> _radioTracks = [];
  int _currentTrackIndex = -1;
  MusicPlaybackMode _playbackMode = MusicPlaybackMode.listLoop;
  bool _isBackgroundMusicPlaying = false;
  double _backgroundMusicVolume = 0.5;
  bool _isLoadingMusic = false;

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
              'http://101.132.38.216:8800/download?id=1866350557',
        ),
        MusicTrack(
          id: 'def_2',
          title: "It's Okay",
          artist: 'Ayzic / Project AER',
          sourceUrl:
              'http://101.132.38.216:8800/download?id=1840791849',
        ),
        MusicTrack(
          id: 'def_3',
          title: 'Hiraeth',
          artist: 'Bcalm / Banks',
          sourceUrl:
              'http://101.132.38.216:8800/download?id=1902794853',
        ),
        MusicTrack(
          id: "def_4",
          title: "Cascade",
          artist: "kinissue / Ayzic",
          sourceUrl: 'http://101.132.38.216:8800/download?id=1855900632',
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
      final dir = await getApplicationDocumentsDirectory();
      final filename = '${track.id}.mp3';
      final file = File('${dir.path}/$filename');

      final response = await http.get(Uri.parse(track.sourceUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        final index = _defaultTracks.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          _defaultTracks[index] = _defaultTracks[index].copyWith(
            isLocal: true,
            localPath: file.path,
          );
        }
      }
    } catch (e) {
      debugPrint("Download error: $e");
    } finally {
      _isLoadingMusic = false;
      _safeNotify();
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
      String url = track.localPath ?? track.sourceUrl;
      if (track.isLocal || track.localPath != null) {
         await _backgroundMusicPlayer.setAudioSource(AudioSource.file(url));
      } else {
         await _backgroundMusicPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
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
      if (_activeQueue == _playlist)
        queueName = 'local';
      else if (_activeQueue == _defaultTracks)
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
