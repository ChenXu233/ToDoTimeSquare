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

  void _initBackgroundMusicPlayer() {
    _backgroundMusicPlayer.playerStateStream.listen((state) {
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
    fetchRadioTracks();
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
              'https://m801.music.126.net/20251212194911/25b513be72c384080e8656d57b666a24/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/10141630092/3753/1062/9868/5759e313b0f77c2aff037ce5aa655f13.mp3',
        ),
        MusicTrack(
          id: 'def_2',
          title: "It's Okay",
          artist: 'Ayzic / Project AER',
          sourceUrl:
              'http://m801.music.126.net/20251212193856/35ea3b4662577f4eb9adbf7d21c6cfbe/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/8697392598/33a9/6233/90bd/0f02755e78a31d307cbc6ce042c2ebd6.mp3',
        ),
        MusicTrack(
          id: 'def_3',
          title: 'Frozen Waters',
          artist: 'hoogway / softy',
          sourceUrl:
              'http://m701.music.126.net/20251212194258/a9214462483fa71f4ed6e25616d99098/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/10141630278/e916/e474/806a/331720d42f0d41d4e3c79aea44fc67c2.mp3',
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
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _radioTracks = data.map((e) {
          final map = e as Map<String, dynamic>;
          map['isRadio'] = true;
          return MusicTrack.fromJson(map);
        }).toList();
        notifyListeners();
      }
    
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching radio tracks: $e');
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
      notifyListeners();
    }
  }

  Future<void> _saveImportedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = _playlist.where((t) => t.isLocal && t.localPath != null)
        .map((t) => t.localPath!)
        .toList();
    await prefs.setStringList('pomodoro_importedMusicPaths', paths);
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
    notifyListeners();
  }

  Future<void> downloadTrack(MusicTrack track) async {
    if (track.isLocal || track.localPath != null) return;
    
    _isLoadingMusic = true;
    notifyListeners();

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
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      debugPrint("Error playing track: $e");
    }
  }
  
  List<MusicTrack> _activeQueue = [];

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
    
    notifyListeners();
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
    if (!_backgroundMusicPlayer.playing && currentTrack != null) {
      await _backgroundMusicPlayer.play();
    }
  }

  Future<void> setBackgroundMusicVolume(double volume) async {
    _backgroundMusicVolume = volume;
    await _backgroundMusicPlayer.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pomodoro_backgroundMusicVolume', volume);
    notifyListeners();
  }
  
  Future<void> seekTo(Duration position) async {
    await _backgroundMusicPlayer.seek(position);
  }

  @override
  void dispose() {
    _backgroundMusicPlayer.dispose();
    super.dispose();
  }
}
