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
  APPi18n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
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

  /// Label for auto-play background music setting
  ///
  /// In en, this message translates to:
  /// **'Auto-play background music'**
  String get autoPlayBackgroundMusic;

  /// Subtitle/description for auto-play background music setting
  ///
  /// In en, this message translates to:
  /// **'Resume/pause background music when timer starts or pauses'**
  String get autoPlayBackgroundMusicSubtitle;

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

  /// Music library title
  ///
  /// In en, this message translates to:
  /// **'Music Library'**
  String get musicLibrary;

  /// Title for music cache section
  ///
  /// In en, this message translates to:
  /// **'Music Cache'**
  String get musicCache;

  /// Label prefix for current cache size
  ///
  /// In en, this message translates to:
  /// **'Current cache:'**
  String get currentCache;

  /// Label for max cache input
  ///
  /// In en, this message translates to:
  /// **'Max cache (MB)'**
  String get maxCacheMb;

  /// Button label to clear cache
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCache;

  /// Label for source code link
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// Snackbar text when cache max updated
  ///
  /// In en, this message translates to:
  /// **'Cache max updated'**
  String get cacheMaxUpdated;

  /// Snackbar text when cache cleared
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// Snackbar text when URL cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open URL'**
  String get couldNotOpenUrl;

  /// No local music imported message
  ///
  /// In en, this message translates to:
  /// **'No local music imported'**
  String get noLocalMusicImported;

  /// Import from device button label
  ///
  /// In en, this message translates to:
  /// **'Import from Device'**
  String get importFromDevice;

  /// Add more button label
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// Tab label: Local
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localTab;

  /// Tab label: Default
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultTab;

  /// Tab label: Radio
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get radioTab;

  /// No default tracks available message
  ///
  /// In en, this message translates to:
  /// **'No default tracks available'**
  String get noDefaultTracks;

  /// No radio stations available message
  ///
  /// In en, this message translates to:
  /// **'No radio stations available'**
  String get noRadioStationsAvailable;

  /// No music selected message
  ///
  /// In en, this message translates to:
  /// **'No music selected'**
  String get noMusicSelected;

  /// No local music available message
  ///
  /// In en, this message translates to:
  /// **'No local music available'**
  String get noLocalMusicAvailable;

  /// Playback mode: list loop
  ///
  /// In en, this message translates to:
  /// **'List Loop'**
  String get listLoop;

  /// Playback mode: shuffle
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// Playback mode: radio
  ///
  /// In en, this message translates to:
  /// **'Radio Mode'**
  String get radioMode;

  /// Volume control dialog title
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Message shown when no tasks exist
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// Title for task actions menu
  ///
  /// In en, this message translates to:
  /// **'Task Actions'**
  String get taskActions;

  /// Label for today's focus time
  ///
  /// In en, this message translates to:
  /// **'Today\'s Focus'**
  String get todayFocus;

  /// Label for this week's focus time
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Focus'**
  String get thisWeekFocus;

  /// Label for total accumulated focus time
  ///
  /// In en, this message translates to:
  /// **'Total Focus'**
  String get totalFocus;

  /// Suffix for number of sessions today
  ///
  /// In en, this message translates to:
  /// **'sessions today'**
  String get sessionsToday;

  /// Label for task completion rate
  ///
  /// In en, this message translates to:
  /// **'Task Completion Rate'**
  String get taskCompletionRate;

  /// Text showing number of completed tasks
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String tasksCompleted(int count);

  /// Text showing total number of tasks
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String tasksTotal(int count);

  /// Title for weekly focus trend chart
  ///
  /// In en, this message translates to:
  /// **'Weekly Focus Trend'**
  String get weeklyFocusTrend;

  /// Title for task focus ranking list
  ///
  /// In en, this message translates to:
  /// **'Task Focus Ranking'**
  String get taskFocusRanking;

  /// Message shown when no focus data available
  ///
  /// In en, this message translates to:
  /// **'Start focusing to see trends'**
  String get noFocusDataYet;

  /// Text showing number of focus sessions
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String focusSessions(int count);

  /// Abbreviation for minutes
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// Prefix for top ranking
  ///
  /// In en, this message translates to:
  /// **'Top {count}'**
  String topRanking(int count);

  /// Title for habit tracking section
  ///
  /// In en, this message translates to:
  /// **'Habit Tracking'**
  String get habitTracking;

  /// Status text for checked-in habits
  ///
  /// In en, this message translates to:
  /// **'checked in'**
  String get checkedIn;

  /// Action text for check-in button
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// Message when habit check-in is successful
  ///
  /// In en, this message translates to:
  /// **'Great job! Keep it up!'**
  String get checkInSuccess;

  /// Text for habit streak days
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get streakDays;

  /// Title for adding a new habit
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// Title for editing an existing habit
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabit;

  /// Label for habit name input
  ///
  /// In en, this message translates to:
  /// **'Habit Name'**
  String get habitName;

  /// Placeholder for habit name input
  ///
  /// In en, this message translates to:
  /// **'e.g., Read for 30 minutes'**
  String get habitNamePlaceholder;

  /// Label for habit description input
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get habitDescription;

  /// Label for habit color selection
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get habitColor;

  /// Message when no habits exist yet
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabitsYet;

  /// Prompt to create the first habit
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to create your first habit'**
  String get createFirstHabit;

  /// Snackbar message when notification service fails to initialize
  ///
  /// In en, this message translates to:
  /// **'Notification service unavailable'**
  String get notificationServiceUnavailable;

  /// Debug message for successful database initialization
  ///
  /// In en, this message translates to:
  /// **'Database initialized successfully'**
  String get databaseInitSuccess;

  /// Debug message for failed database initialization
  ///
  /// In en, this message translates to:
  /// **'Database initialization failed'**
  String get databaseInitFailed;

  /// Auto language selection option
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// Network timeout error message
  ///
  /// In en, this message translates to:
  /// **'Network connection timeout, please check your network settings'**
  String get errorNetworkTimeout;

  /// Network connection error message
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to server, please check your network connection'**
  String get errorNetworkConnection;

  /// Network request failed message
  ///
  /// In en, this message translates to:
  /// **'Network request failed'**
  String get errorNetworkRequest;

  /// Domain resolution error message
  ///
  /// In en, this message translates to:
  /// **'Unable to resolve domain name, please check your network connection'**
  String get errorNetworkDomain;

  /// Generic network error message
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorNetworkGeneric;

  /// File not found error message
  ///
  /// In en, this message translates to:
  /// **'File does not exist, it may have been moved or deleted'**
  String get errorFileNotFound;

  /// File permission error message
  ///
  /// In en, this message translates to:
  /// **'No file access permission, please check app permission settings'**
  String get errorFilePermission;

  /// File in use error message
  ///
  /// In en, this message translates to:
  /// **'File is being used by another program, please close other apps and retry'**
  String get errorFileInUse;

  /// Generic file error message
  ///
  /// In en, this message translates to:
  /// **'File access error'**
  String get errorFileGeneric;

  /// Unsupported audio format message
  ///
  /// In en, this message translates to:
  /// **'Audio format not supported, unable to play this file'**
  String get errorAudioFormat;

  /// Audio duration error message
  ///
  /// In en, this message translates to:
  /// **'Unable to get audio duration information'**
  String get errorAudioDuration;

  /// Generic audio error message
  ///
  /// In en, this message translates to:
  /// **'Audio playback error'**
  String get errorAudioGeneric;

  /// Generic playback error message
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get errorPlaybackGeneric;

  /// Generic cache error message
  ///
  /// In en, this message translates to:
  /// **'Cache error'**
  String get errorCacheGeneric;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorUnknown;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Notification title when focus ends
  ///
  /// In en, this message translates to:
  /// **'Focus ended'**
  String get notificationFocusEnded;

  /// Notification title when break ends
  ///
  /// In en, this message translates to:
  /// **'Break ended'**
  String get notificationBreakEnded;

  /// Notification body when focus ends
  ///
  /// In en, this message translates to:
  /// **'Time for a break!'**
  String get notificationTimeToBreak;

  /// Notification body when break ends
  ///
  /// In en, this message translates to:
  /// **'Time to focus!'**
  String get notificationTimeToFocus;

  /// Notification skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get notificationSkip;

  /// Notification reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get notificationReset;

  /// Message when database is already initialized
  ///
  /// In en, this message translates to:
  /// **'Database already initialized'**
  String get databaseAlreadyInitialized;

  /// Message when database initialization is complete
  ///
  /// In en, this message translates to:
  /// **'Database initialization complete'**
  String get databaseInitComplete;

  /// Error when database not initialized
  ///
  /// In en, this message translates to:
  /// **'Database not initialized, please call initialize() first'**
  String get databaseNotInitialized;

  /// Default task name when unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown task'**
  String get unknownTask;

  /// Message when migration is complete
  ///
  /// In en, this message translates to:
  /// **'Migration complete: {todosMigrated} tasks, {focusRecordsMigrated} records'**
  String migrationComplete(int todosMigrated, int focusRecordsMigrated);

  /// Hint text for parent task search
  ///
  /// In en, this message translates to:
  /// **'Search parent task...'**
  String get searchParentTask;
}

class _APPi18nDelegate extends LocalizationsDelegate<APPi18n> {
  const _APPi18nDelegate();

  @override
  Future<APPi18n> load(Locale locale) {
    return SynchronousFuture<APPi18n>(lookupAPPi18n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_APPi18nDelegate old) => false;
}

APPi18n lookupAPPi18n(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return APPi18nEn();
    case 'zh': return APPi18nZh();
  }

  throw FlutterError(
    'APPi18n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
