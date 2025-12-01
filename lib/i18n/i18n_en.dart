// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'i18n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class APPi18nEn extends APPi18n {
  APPi18nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Todo Time Square';

  @override
  String get welcomeMessage => 'Welcome to Todo Time Square';

  @override
  String get addTask => 'Add Task';

  @override
  String get taskName => 'Task Name';

  @override
  String get taskDescription => 'Task Description';

  @override
  String get taskDueDate => 'Due Date';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get completed => 'Completed';

  @override
  String get allTasks => 'All Tasks';

  @override
  String get todayTasks => 'Today\'s Tasks';

  @override
  String get upcomingTasks => 'Upcoming Tasks';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get notification => 'Notification';

  @override
  String get about => 'About';

  @override
  String get pomodoroTitle => 'Pomodoro Timer';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get reset => 'Reset';

  @override
  String get focusTime => 'Focus Time';

  @override
  String get shortBreak => 'Short Break';

  @override
  String get longBreak => 'Long Break';

  @override
  String get pomodoroStatusFocus => 'Focus';

  @override
  String get pomodoroStatusShortBreak => 'Short Break';

  @override
  String get pomodoroStatusLongBreak => 'Long Break';

  @override
  String get help => 'Help';

  @override
  String get importance => 'Importance';

  @override
  String get duration => 'Duration';

  @override
  String get startTime => 'Start Time';

  @override
  String get notSet => 'Not set';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get pomodoroSettings => 'Pomodoro Settings';

  @override
  String get pomodoroInfo => 'Pomodoro Technique';

  @override
  String get pomodoroInfoContent =>
      'The Pomodoro Technique uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks. This app simplifies it to just Focus and Short Break cycles.';

  @override
  String get homeMessage => 'Focus. Organize. Achieve.';

  @override
  String get alarmSound => 'Alarm Sound';
}
