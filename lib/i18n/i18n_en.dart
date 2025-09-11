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
  String get language => 'Language';

  @override
  String get notification => 'Notification';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';
}
