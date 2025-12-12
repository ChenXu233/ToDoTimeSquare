import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'i18n_en.dart';
import 'i18n_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of APPi18n
/// returned by `APPi18n.of(context)`.
///
/// Applications need to include `APPi18n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/i18n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: APPi18n.localizationsDelegates,
///   supportedLocales: APPi18n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the APPi18n.supportedLocales
/// property.
abstract class APPi18n {
  APPi18n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static APPi18n? of(BuildContext context) {
    return Localizations.of<APPi18n>(context, APPi18n);
  }

  static const LocalizationsDelegate<APPi18n> delegate = _APPi18nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Todo Time Square'**
  String get appTitle;

  /// The welcome message displayed on the application launch
  ///
  /// In en, this message translates to:
  /// **'Welcome to Todo Time Square'**
  String get welcomeMessage;

  /// The label for the add task button
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// The label for the task name input field
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskName;

  /// The label for the task description input field
  ///
  /// In en, this message translates to:
  /// **'Task Description'**
  String get taskDescription;

  /// The label for the task due date input field
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get taskDueDate;

  /// The label for the save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// The label for the cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// The label for the delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// The label for the edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// The label for the completed tasks filter
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// The label for the all tasks filter
  ///
  /// In en, this message translates to:
  /// **'All Tasks'**
  String get allTasks;

  /// The label for the today tasks filter
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todayTasks;

  /// The label for the upcoming tasks filter
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// The label for the settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// The label for the dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// The label for the theme mode selection
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// The label for light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// The label for dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// The label for system theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// The label for the language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// The label for the notification settings
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// The label for the about section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// The title for the pomodoro timer feature
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Timer'**
  String get pomodoroTitle;

  /// The label for the start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// The label for the start task action
  ///
  /// In en, this message translates to:
  /// **'Start Task'**
  String get startTask;

  /// The label for the pause button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// The label for the resume button
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// The label for the reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// The label for the focus time duration
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTime;

  /// The label for the short break duration
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// The label for the long break duration
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreak;

  /// The status text for focus mode
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get pomodoroStatusFocus;

  /// The status text for short break mode
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get pomodoroStatusShortBreak;

  /// The status text for long break mode
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get pomodoroStatusLongBreak;

  /// Heading for the active task panel
  ///
  /// In en, this message translates to:
  /// **'Current Task'**
  String get currentTask;

  /// Button label to mark task completed
  ///
  /// In en, this message translates to:
  /// **'Complete Task'**
  String get completeTask;

  /// Dialog title shown after finishing a task
  ///
  /// In en, this message translates to:
  /// **'Task Completed'**
  String get taskCompletedDialogTitle;

  /// Dialog message shown after finishing a task
  ///
  /// In en, this message translates to:
  /// **'Awesome focus! Your task is now complete. Celebrate the win or pick another mission when you\'re ready.'**
  String get taskCompletedDialogMessage;

  /// Button label inside completion dialog
  ///
  /// In en, this message translates to:
  /// **'Keep Going'**
  String get taskCompletedDialogButton;

  /// The label for the help section
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// The label for the importance level
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get importance;

  /// The label for the duration field
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// The label for the start time field
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// The text displayed when a value is not set
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// The text for low importance level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// The text for medium importance level
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// The text for high importance level
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// The validation message for empty title
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// The title for pomodoro settings
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Settings'**
  String get pomodoroSettings;

  /// The title for pomodoro technique information
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Technique'**
  String get pomodoroInfo;

  /// The description content explaining the pomodoro technique
  ///
  /// In en, this message translates to:
  /// **'The Pomodoro Technique uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks. This app simplifies it to just Focus and Short Break cycles.'**
  String get pomodoroInfoContent;

  /// The meesgae of the home
  ///
  /// In en, this message translates to:
  /// **'Focus. Organize. Achieve.'**
  String get homeMessage;

  /// The label for the alarm sound setting
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get alarmSound;

  /// The version of the app
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// A message from the developer about the app
  ///
  /// In en, this message translates to:
  /// **'This app is a project I had in mind when I was working on it. I hope it can help others better manage their time and tasks. If you have any suggestions or feedback, please feel free to contact me!'**
  String get somethingIWantToSay;

  /// The label for details button
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// The label for share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Detailed description of the app and its unique features
  ///
  /// In en, this message translates to:
  /// **'ToDoTimeSquare is a productivity app designed specifically for those who prefer a flexible and open cognitive style (P type personality in MBTI). Its core innovation lies in deeply integrating an unstructured dynamic task pool with the standard Pomodoro Technique, forming a \'free choice, focused execution\' cycle system: The app provides an open to-do list as a \'task reserve pool\' without mandatory ordering, allowing users to add or delete tasks at any time. Users do not need to plan their entire day\'s schedule in advance; instead, they can instantly select a single task from the pool based on their current state and interests, then start a customized Pomodoro timer (e.g., 25 minutes of focus + 5 minutes of break) to enter a protected flow sprint phase. After each Pomodoro session, the system provides immediate visual feedback and data statistics, automatically marking the task as completed. Users can either continue with the same task for the next sprint or freely choose a new goal from the list without any burden. This design effectively reduces decision-making barriers and procrastination tendencies by breaking down macro planning pressure into micro autonomous action units, transforming a flexible and scattered thinking style into sustainable focused productivity. Time management is no longer a framework that restricts exploration but a tool that supports spontaneous creation.'**
  String get appdetails;

  /// The label for the statistics section
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Label for reminder mode setting
  ///
  /// In en, this message translates to:
  /// **'Reminder Mode'**
  String get reminderMode;

  /// Label for no reminder
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get reminderNone;

  /// Label for notification only reminder
  ///
  /// In en, this message translates to:
  /// **'Notification Only'**
  String get reminderNotification;

  /// Label for alarm only reminder
  ///
  /// In en, this message translates to:
  /// **'Alarm Only'**
  String get reminderAlarm;

  /// Label for all reminders
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reminderAll;

  /// The label for the parent task dropdown
  ///
  /// In en, this message translates to:
  /// **'Parent Task'**
  String get parentTask;

  /// The label for no parent task option
  ///
  /// In en, this message translates to:
  /// **'No Parent Task'**
  String get noparent;

  /// The label for the reset to default button
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// The label for minutes
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;
}

class _APPi18nDelegate extends LocalizationsDelegate<APPi18n> {
  const _APPi18nDelegate();

  @override
  Future<APPi18n> load(Locale locale) {
    return SynchronousFuture<APPi18n>(lookupAPPi18n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_APPi18nDelegate old) => false;
}

APPi18n lookupAPPi18n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return APPi18nEn();
    case 'zh':
      return APPi18nZh();
  }

  throw FlutterError(
    'APPi18n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
