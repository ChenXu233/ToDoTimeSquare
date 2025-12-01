import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroStatus { focus, shortBreak }

class PomodoroProvider extends ChangeNotifier {
  int _focusDuration = 25 * 60;
  int _shortBreakDuration = 5 * 60;

  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  PomodoroStatus _status = PomodoroStatus.focus;
  bool _isRunning = false;
  bool _isRinging = false;
  DateTime? _targetTime;
  final AudioPlayer _audioPlayer = AudioPlayer();

  int get remainingSeconds => _remainingSeconds;
  PomodoroStatus get status => _status;
  bool get isRunning => _isRunning;
  bool get isRinging => _isRinging;

  int get focusDuration => _focusDuration;
  int get shortBreakDuration => _shortBreakDuration;

  PomodoroProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _focusDuration = prefs.getInt('focusDuration') ?? 25 * 60;
    _shortBreakDuration = prefs.getInt('shortBreakDuration') ?? 5 * 60;

    await _restoreState(prefs);
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
        _remainingSeconds = 0;
        _isRunning = false;
        _targetTime = null;
        _saveState();
        _startAlarm();
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
  }

  Future<void> updateSettings({int? focus, int? shortBreak}) async {
    final prefs = await SharedPreferences.getInstance();
    if (focus != null) {
      _focusDuration = focus;
      await prefs.setInt('focusDuration', focus);
    }
    if (shortBreak != null) {
      _shortBreakDuration = shortBreak;
      await prefs.setInt('shortBreakDuration', shortBreak);
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
    return 1.0 - (_remainingSeconds / totalSeconds);
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
    notifyListeners();
  }

  void _startTimerInternal() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_targetTime != null && now.isBefore(_targetTime!)) {
        final newRemaining = _targetTime!.difference(now).inSeconds;
        if (newRemaining != _remainingSeconds) {
          _remainingSeconds = newRemaining;
          notifyListeners();
        }
      } else {
        _timer?.cancel();
        _timer = null;
        _isRunning = false;
        _remainingSeconds = 0;
        _targetTime = null;
        _saveState();
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
    notifyListeners();
  }

  void resetTimer() {
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

    _saveState();
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
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        UrlSource(
          'https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg',
        ),
      );
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void stopAlarm() {
    if (_isRinging) {
      _isRinging = false;
      _audioPlayer.stop();
      _switchNextStatus();
      startTimer(); // Auto start next phase
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

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
