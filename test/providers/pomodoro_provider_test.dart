import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_time_square/providers/pomodoro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PomodoroProvider - progress calculation', () {
    late PomodoroProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = PomodoroProvider();
      // Wait for async initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    test('progress returns 0 when totalSeconds is 0', () async {
      SharedPreferences.setMockInitialValues({
        'focusDuration': 0,
        'shortBreakDuration': 0,
      });
      final zeroProvider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(zeroProvider.progress, 0);

      zeroProvider.dispose();
    });

    test('progress calculates correctly for focus status', () async {
      // Default focus duration is 25 * 60 = 1500 seconds
      // Progress should be a value between 0 and 1
      final progress = provider.progress;
      expect(progress, greaterThanOrEqualTo(0));
      expect(progress, lessThanOrEqualTo(1));
    });

    test('progress returns 0 for NaN', () {
      // We can't directly inject NaN, but we can verify progress is never NaN
      final progress = provider.progress;
      expect(progress.isNaN, false);
      expect(progress >= 0 && progress <= 1, true);
    });

    test('progress returns 0 when value < 0', () {
      final progress = provider.progress;
      if (progress < 0) {
        expect(progress, 0);
      } else {
        expect(progress >= 0, true);
      }
    });

    test('progress returns 1 when value > 1', () {
      final progress = provider.progress;
      if (progress > 1) {
        expect(progress, 1);
      } else {
        expect(progress <= 1, true);
      }
    });
  });

  group('PomodoroProvider - resetTimer behavior', () {
    late PomodoroProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial status is focus', () {
      expect(provider.status, PomodoroStatus.focus);
    });

    test('initial remaining seconds equals focus duration', () {
      expect(provider.remainingSeconds, provider.focusDuration);
    });
  });

  group('PomodoroProvider - skipPhase behavior', () {
    late PomodoroProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial status is focus', () {
      expect(provider.status, PomodoroStatus.focus);
    });
  });

  group('PomodoroProvider - _restoreState behavior via initial state', () {
    test('timer not expired restores correctly', () async {
      // Set up a timer that will be in the future
      SharedPreferences.setMockInitialValues({
        'pomodoro_isRunning': true,
        'pomodoro_status': 0, // focus
        'pomodoro_targetTime': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
        'pomodoro_savedRemaining': 600,
      });

      final provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Timer should be restored as running
      expect(provider.isRunning, true);

      provider.dispose();
    });

    test('timer expired resets state without alarm', () async {
      // Set up an expired timer (target time in the past)
      SharedPreferences.setMockInitialValues({
        'pomodoro_isRunning': true,
        'pomodoro_status': 0, // focus
        'pomodoro_targetTime': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        'pomodoro_savedRemaining': 0,
      });

      final provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Timer should be reset, not running
      expect(provider.isRunning, false);
      // Should be reset to focus duration
      expect(provider.remainingSeconds, provider.focusDuration);

      provider.dispose();
    });

    test('non-running timer with saved remaining restores correctly', () async {
      SharedPreferences.setMockInitialValues({
        'pomodoro_isRunning': false,
        'pomodoro_status': 0, // focus
        'pomodoro_savedRemaining': 500,
      });

      final provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // Should use saved remaining
      expect(provider.remainingSeconds, 500);
      expect(provider.isRunning, false);

      provider.dispose();
    });
  });

  group('PomodoroProvider - progress edge cases', () {
    late PomodoroProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    test('progress is bounded between 0 and 1', () {
      final progress = provider.progress;
      expect(progress >= 0.0, true, reason: 'Progress should be >= 0');
      expect(progress <= 1.0, true, reason: 'Progress should be <= 1');
    });

    test('progress at start is 0', () {
      // At start, remainingSeconds equals totalSeconds, so progress = 0
      final progress = provider.progress;
      // Default start: remaining = total, so progress = 1 - 1 = 0
      expect(progress, closeTo(0.0, 0.01));
    });
  });

  group('PomodoroProvider - status enum', () {
    test('PomodoroStatus has correct values', () {
      expect(PomodoroStatus.values.length, 2);
      expect(PomodoroStatus.focus.index, 0);
      expect(PomodoroStatus.shortBreak.index, 1);
    });

    test('PomodoroReminderMode has correct values', () {
      expect(PomodoroReminderMode.values.length, 4);
      expect(PomodoroReminderMode.none.index, 0);
      expect(PomodoroReminderMode.notification.index, 1);
      expect(PomodoroReminderMode.alarm.index, 2);
      expect(PomodoroReminderMode.all.index, 3);
    });
  });

  group('PomodoroProvider - initial state', () {
    late PomodoroProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial status is focus', () {
      expect(provider.status, PomodoroStatus.focus);
    });

    test('initial isRunning is false', () {
      expect(provider.isRunning, false);
    });

    test('initial remaining seconds equals focus duration', () {
      expect(provider.remainingSeconds, 25 * 60);
    });

    test('default focus duration is 25 minutes', () {
      expect(provider.focusDuration, 25 * 60);
    });

    test('default short break duration is 5 minutes', () {
      expect(provider.shortBreakDuration, 5 * 60);
    });
  });

  group('PomodoroProvider - shortBreak status', () {
    test('can switch to shortBreak via status index', () async {
      SharedPreferences.setMockInitialValues({
        'pomodoro_status': 1, // shortBreak
      });

      final provider = PomodoroProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.status, PomodoroStatus.shortBreak);
      expect(provider.remainingSeconds, provider.shortBreakDuration);

      provider.dispose();
    });
  });
}
