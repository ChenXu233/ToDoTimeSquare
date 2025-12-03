import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // 创建高优先级弹窗通知渠道（如 Telegram 顶部弹窗）
    const AndroidNotificationChannel headsUpChannel =
        AndroidNotificationChannel(
          'heads_up_channel',
          'Heads Up Notifications',
          description: '用于顶部弹窗和驻留通知',
          importance: Importance.max,
          playSound: true,
        );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
          windows: WindowsInitializationSettings(
            appName: 'Todo Time Square',
            appUserModelId: 'com.example.todotimesquare',
            guid: '12345678-1234-1234-1234-123456789abc',
          ),
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 注册 heads-up 通知渠道
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(headsUpChannel);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// 顶部弹窗+驻留后台的系统原生通知
  Future<void> showHeadsUpNotification({
    required int id,
    required String title,
    required String body,
    bool ongoing = true,
  }) async {
    final actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        'SKIP_ACTION',
        '跳过',
        icon: DrawableResourceAndroidBitmap('mipmap/ic_launcher'),
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'RESET_ACTION',
        '重置',
        icon: DrawableResourceAndroidBitmap('mipmap/ic_launcher'),
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'heads_up_channel',
          'Heads Up Notifications',
          channelDescription: '用于顶部弹窗和驻留通知',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Heads Up',
          enableVibration: true,
          playSound: true,
          ongoing: ongoing, // 通知驻留
          visibility: NotificationVisibility.public,
          actions: actions,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBanner: true,
        ),
      ),
    );
  }

  /// 保留原有定时通知方法
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required bool useAlarmChannel,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        'SKIP_ACTION',
        '跳过',
        icon: DrawableResourceAndroidBitmap('mipmap/ic_launcher'),
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'RESET_ACTION',
        '重置',
        icon: DrawableResourceAndroidBitmap('mipmap/ic_launcher'),
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          useAlarmChannel
              ? 'pomodoro_alarm_channel'
              : 'pomodoro_notification_channel',
          useAlarmChannel ? 'Pomodoro Alarm' : 'Pomodoro Notification',
          channelDescription: useAlarmChannel
              ? 'Channel for Pomodoro Alarms'
              : 'Channel for Pomodoro Notifications',
          importance: Importance.max, // 最大重要性
          priority: Priority.high, // 高优先级
          audioAttributesUsage: useAlarmChannel
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public, // 锁屏可见
          ticker: 'Pomodoro Finished', // 状态栏滚动提示
          fullScreenIntent: useAlarmChannel, // 闹钟时弹窗
          category: useAlarmChannel
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.reminder,
          actions: actions,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBanner: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
