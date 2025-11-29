import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroStatus {
  focus,
  shortBreak,
}

class PomodoroProvider extends ChangeNotifier {
  int _focusDuration = 25 * 60;
  int _shortBreakDuration = 5 * 60;

  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  PomodoroStatus _status = PomodoroStatus.focus;
  bool _isRunning = false;
  bool _isRinging = false;
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
    resetTimer();
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _timer = null;
        _isRunning = false;
        _startAlarm();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    stopAlarm();
    switch (_status) {
      case PomodoroStatus.focus:
        _remainingSeconds = _focusDuration;
        break;
      case PomodoroStatus.shortBreak:
        _remainingSeconds = _shortBreakDuration;
        break;
    }
    notifyListeners();
  }

  void setStatus(PomodoroStatus status) {
    pauseTimer();
    stopAlarm();
    _status = status;
    resetTimer();
  }

  Future<void> _startAlarm() async {
    _isRinging = true;
    notifyListeners();
    // Play a sound. Using a default source for now.
    // In a real app, you'd bundle an asset.
    // For this demo, we'll try to play a network sound or just simulate it if offline.
    // Ideally, user should provide 'assets/sounds/alarm.mp3'.
    try {
       await _audioPlayer.setReleaseMode(ReleaseMode.loop);
       await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void stopAlarm() {
    if (_isRinging) {
      _isRinging = false;
      _audioPlayer.stop();
      _switchNextStatus();
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
    // Auto-start next timer? The user said "automatically enter rest", 
    // but usually that means state switch. 
    // If they want it to run, we'd call startTimer().
    // Let's just switch state for now, as auto-starting can be annoying.
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
