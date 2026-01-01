import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'background_music_provider.dart';
import '../models/repositories/focus_record_repository.dart';
import 'statistics_provider.dart';

enum PomodoroStatus { focus, shortBreak }

enum PomodoroReminderMode { none, notification, alarm, all }



class PomodoroProvider extends ChangeNotifier {
  int _focusDuration = 25 * 60;
  int _shortBreakDuration = 5 * 60;
  String _alarmSoundPath = 'audio/alarm_sound.ogg'; // 默认内置铃声

  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  PomodoroStatus _status = PomodoroStatus.focus;
  bool _isRunning = false;
  bool _isRinging = false;
  DateTime? _targetTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  


  PomodoroReminderMode _reminderMode = PomodoroReminderMode.none;
  bool _autoPlayBackgroundMusic = false;

  int get remainingSeconds => _remainingSeconds;
  PomodoroStatus get status => _status;
  bool get isRunning => _isRunning;
  bool get isRinging => _isRinging;
  PomodoroReminderMode get reminderMode => _reminderMode;

  int get focusDuration => _focusDuration;
  int get shortBreakDuration => _shortBreakDuration;
  String get alarmSoundPath => _alarmSoundPath;
  bool get autoPlayBackgroundMusic => _autoPlayBackgroundMusic;

  String? get currentTaskId => _currentTaskId;
  String? get currentTaskTitle => _currentTaskTitle;



  String? _currentTaskId;
  String? _currentTaskTitle;

  StatisticsProvider? _statisticsProvider;

  BackgroundMusicProvider? _backgroundMusicProvider;

  void setStatisticsProvider(StatisticsProvider provider) {
    _statisticsProvider = provider;
  }

  void setBackgroundMusicProvider(BackgroundMusicProvider provider) {
    _backgroundMusicProvider = provider;
  }

  PomodoroProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _focusDuration = prefs.getInt('focusDuration') ?? 25 * 60;
    _shortBreakDuration = prefs.getInt('shortBreakDuration') ?? 5 * 60;
    _alarmSoundPath =
        prefs.getString('alarmSoundPath') ?? 'audio/alarm_sound.ogg';

    _currentTaskId = prefs.getString('pomodoro_currentTaskId');
    _currentTaskTitle = prefs.getString('pomodoro_currentTaskTitle');

    int? reminderModeIndex = prefs.getInt('reminderMode');
    if (reminderModeIndex != null &&
        reminderModeIndex >= 0 &&
        reminderModeIndex < PomodoroReminderMode.values.length) {
      _reminderMode = PomodoroReminderMode.values[reminderModeIndex];
    }

    _autoPlayBackgroundMusic =
        prefs.getBool('pomodoro_autoPlayBackgroundMusic') ?? false;



    await _restoreState(prefs);
  }

  Future<void> setAlarmSound(String path) async {
    // allow callers to pass 'default' to reset to bundled asset
    final normalizedPath = (path == 'default') ? 'audio/alarm_sound.ogg' : path;
    _alarmSoundPath = normalizedPath;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarmSoundPath', normalizedPath);
    notifyListeners();
  }

  Future<void> setAutoPlayBackgroundMusic(bool enabled) async {
    _autoPlayBackgroundMusic = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pomodoro_autoPlayBackgroundMusic', enabled);
    notifyListeners();
  }



  Future<void> _restoreState(SharedPreferences prefs) async {
    _isRunning = prefs.getBool('pomodoro_isRunning') ?? false;
    int? statusIndex = prefs.getInt('pomodoro_status');
    if (statusIndex != null &&
        statusIndex >= 0 &&
        statusIndex < PomodoroStatus.values.length) {
      _status = PomodoroStatus.values[statusIndex];
    }

    int? targetTimeMillis = prefs.getInt('pomodoro_targetTime');
    int? savedRemaining = prefs.getInt('pomodoro_savedRemaining');

    if (_isRunning && targetTimeMillis != null) {
      final target = DateTime.fromMillisecondsSinceEpoch(targetTimeMillis);
      final now = DateTime.now();
      if (now.isBefore(target)) {
        _targetTime = target;
        _remainingSeconds = target.difference(now).inSeconds;
        _startTimerInternal();
      } else {
        // App was closed and timer expired while closed.
        // Requirement: "Once the app exits, it is no longer counted."
        // So we treat this as an interrupted/invalid session.
        _isRunning = false;
        _targetTime = null;
        _remainingSeconds = _status == PomodoroStatus.focus
            ? _focusDuration
            : _shortBreakDuration;
        _saveState();
        // Do NOT start alarm, do NOT record stats.
        resetTimer();
      }
    } else {
      if (savedRemaining != null) {
        _remainingSeconds = savedRemaining;
      } else {
        _remainingSeconds = _status == PomodoroStatus.focus
            ? _focusDuration
            : _shortBreakDuration;
      }
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pomodoro_isRunning', _isRunning);
    await prefs.setInt('pomodoro_status', _status.index);
    if (_targetTime != null) {
      await prefs.setInt(
        'pomodoro_targetTime',
        _targetTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove('pomodoro_targetTime');
    }
    await prefs.setInt('pomodoro_savedRemaining', _remainingSeconds);

    if (_currentTaskId != null) {
      await prefs.setString('pomodoro_currentTaskId', _currentTaskId!);
    } else {
      await prefs.remove('pomodoro_currentTaskId');
    }
    if (_currentTaskTitle != null) {
      await prefs.setString('pomodoro_currentTaskTitle', _currentTaskTitle!);
    } else {
      await prefs.remove('pomodoro_currentTaskTitle');
    }
  }

  Future<void> updateSettings({
    int? focus,
    int? shortBreak,
    PomodoroReminderMode? reminderMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (focus != null) {
      _focusDuration = focus;
      await prefs.setInt('focusDuration', focus);
    }
    if (shortBreak != null) {
      _shortBreakDuration = shortBreak;
      await prefs.setInt('shortBreakDuration', shortBreak);
    }
    if (reminderMode != null) {
      _reminderMode = reminderMode;
      await prefs.setInt('reminderMode', reminderMode.index);
      if (reminderMode != PomodoroReminderMode.none) {
        await NotificationService().requestPermissions();
      }
    }
    resetTimer();
  }

  double get progress {
    int totalSeconds;
    switch (_status) {
      case PomodoroStatus.focus:
        totalSeconds = _focusDuration;
        break;
      case PomodoroStatus.shortBreak:
        totalSeconds = _shortBreakDuration;
        break;
    }
    if (totalSeconds == 0) return 0;
    final value = 1.0 - (_remainingSeconds / totalSeconds);
    if (value.isNaN) return 0;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  void startTimer() {
    if (_timer != null) return;
    if (_isRinging) {
      stopAlarm();
      return;
    }
    _isRunning = true;
    _targetTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    _saveState();
    _startTimerInternal();
    _scheduleNotification();
    // Start/resume background music when timer starts (only if enabled in settings)
    if (_autoPlayBackgroundMusic) {
      _backgroundMusicProvider?.resumeBackgroundMusic();
    }

    notifyListeners();
  }

  void _startTimerInternal() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_targetTime != null && now.isBefore(_targetTime!)) {
        final newRemaining = _targetTime!.difference(now).inSeconds;
        if (newRemaining != _remainingSeconds) {
          _remainingSeconds = newRemaining + 1;
          notifyListeners();
        }
      } else {
        _timer?.cancel();
        _timer = null;
        _isRunning = false;
        _remainingSeconds = 0;
        _targetTime = null;
        _saveState();

        // Record statistics if it was a focus session
        if (_status == PomodoroStatus.focus && _statisticsProvider != null) {
          _statisticsProvider!.addRecord(
            FocusRecordModel(
              id: DateTime.now().toIso8601String(),
              startTime: DateTime.now().subtract(
                Duration(seconds: _focusDuration),
              ),
              durationSeconds: _focusDuration,
              taskId: _currentTaskId,
              taskTitle: _currentTaskTitle,
              isCompleted: false,
              interruptionCount: 0,
              efficiencyScore: null,
              createdAt: DateTime.now(),
            ),
          );
        }

        // 计时结束时弹出系统原生 heads-up 通知
        if (_reminderMode == PomodoroReminderMode.notification ||
            _reminderMode == PomodoroReminderMode.all) {
          NotificationService().showHeadsUpNotification(
            id: 1,
            title: _status == PomodoroStatus.focus ? '专注结束' : '休息结束',
            body: _status == PomodoroStatus.focus ? '该休息了！' : '该专注了！',
            ongoing: true,
          );
        }
        _startAlarm();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _targetTime = null;
    _saveState();
    _cancelNotification();
    // Pause background music when timer pauses
    _backgroundMusicProvider?.pauseBackgroundMusic();
    notifyListeners();
  }

  bool setTask({required String id, required String title}) {
    if (_currentTaskId == id) return false;

    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _targetTime = null;

    if (_isRinging) {
      _isRinging = false;
      _audioPlayer.stop();
    }
    
    _status = PomodoroStatus.focus;
    _remainingSeconds = _focusDuration;
    _cancelNotification();

    _currentTaskId = id;
    _currentTaskTitle = title;

    _saveState();
    notifyListeners();
    return true;
  }

  void resetTimer({bool clearTask = false}) {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _targetTime = null;

    if (_isRinging) {
      _isRinging = false;
      _audioPlayer.stop();
    }
    
    _status = PomodoroStatus.focus;
    _remainingSeconds = _focusDuration;

    if (clearTask) {
      _currentTaskId = null;
      _currentTaskTitle = null;
    }

    _saveState();
    _cancelNotification();
    // Ensure background music is paused on reset
    _backgroundMusicProvider?.pauseBackgroundMusic();
    notifyListeners();
  }

  void skipPhase() {
    pauseTimer();
    if (_isRinging) {
      stopAlarm();
    } else {
      _switchNextStatus();
      startTimer();
    }
  }

  void setStatus(PomodoroStatus status) {
    pauseTimer();
    stopAlarm();
    _status = status;
    switch (_status) {
      case PomodoroStatus.focus:
        _remainingSeconds = _focusDuration;
        break;
      case PomodoroStatus.shortBreak:
        _remainingSeconds = _shortBreakDuration;
        break;
    }
    _saveState();
    notifyListeners();
  }

  Future<void> _startAlarm() async {
    _isRinging = true;
    notifyListeners();
    // stop background music (if any) when alarm starts
    if (_backgroundMusicProvider != null) {
      await _backgroundMusicProvider!.pauseBackgroundMusic();
    }
    try {
      // Stop any previous playback to avoid races
      await _audioPlayer.stop();
      await _audioPlayer.setLoopMode(LoopMode.one);

      final path = _alarmSoundPath.trim();

      // allow callers or prefs that still have 'default'
      final effectivePath = (path.isEmpty || path == 'default')
          ? 'audio/alarm_sound.ogg'
          : path;

      if (effectivePath.startsWith('http')) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(effectivePath)),
        );
      } else if (effectivePath.startsWith('file://')) {
        // file:// URIs => convert to local file
        final uri = Uri.parse(effectivePath);
        if (kIsWeb) throw Exception('file:// not supported on web');
        final f = File.fromUri(uri);
        if (await f.exists()) {
          await _audioPlayer.setAudioSource(AudioSource.file(f.path));
        } else {
          throw Exception('Alarm file not found: ${f.path}');
        }
      } else if (!kIsWeb && File(effectivePath).existsSync()) {
        // absolute/local path
        await _audioPlayer.setAudioSource(AudioSource.file(effectivePath));
      } else {
        // treat as asset path (normalize common variants)
        final assetPath = effectivePath.startsWith('assets/')
            ? effectivePath
            : 'assets/$effectivePath';
        await _audioPlayer.setAudioSource(AudioSource.asset(assetPath));
      }

      await _audioPlayer.play();
    } catch (e, st) {
      debugPrint("Error playing audio: $e\n$st");
      // ensure state is consistent for UI
      _isRinging = false;
      notifyListeners();
    }
  }

  void stopAlarm() {
    if (_isRinging) {
      _isRinging = false;
      _audioPlayer.stop();
      _cancelNotification();
      _switchNextStatus();
      startTimer(); // Auto start next phase
      // startTimer will resume background music if set
      notifyListeners();
    }
  }

  void _switchNextStatus() {
    if (_status == PomodoroStatus.focus) {
      _status = PomodoroStatus.shortBreak;
      _remainingSeconds = _shortBreakDuration;
    } else {
      _status = PomodoroStatus.focus;
      _remainingSeconds = _focusDuration;
    }
  }

  void _scheduleNotification() {
    if (_targetTime == null) return;
    if (_reminderMode == PomodoroReminderMode.none) return;

    bool useAlarm =
        _reminderMode == PomodoroReminderMode.alarm ||
        _reminderMode == PomodoroReminderMode.all;

    NotificationService().scheduleNotification(
      id: 0,
      title: _status == PomodoroStatus.focus
          ? 'Focus Time Finished'
          : 'Break Time Finished',
      body: _status == PomodoroStatus.focus
          ? 'Time to take a break!'
          : 'Time to focus!',
      scheduledDate: _targetTime!,
      useAlarmChannel: useAlarm,
    );
  }

  void _cancelNotification() {
    NotificationService().cancel(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
