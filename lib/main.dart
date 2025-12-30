import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'routes/app_router.dart'; // 导入路由配置
import 'i18n/i18n.dart'; // 导入生成的国际化文件
import 'providers/theme_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/background_music_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/statistics_provider.dart';
import 'widgets/window/window_title_bar.dart';
import 'services/notification_service.dart';

// Global key used to show SnackBars from main when services fail to initialize.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  // Do NOT await NotificationService here — initialize it after the app
  // UI is up so failures don't prevent the app from starting.

  if (_isDesktopPlatform() && !_isTestEnvironment()) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(1280, 720);
      win.minSize = const Size(480, 800);
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = "Todo Time Square";
      win.show();
    });
  }

  if (!kIsWeb && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Error setting high refresh rate: $e');
    }
  }
  runApp(const MyApp());

  // Initialize NotificationService after the first frame so that any
  // initialization failure doesn't block the app. If it fails, show a
  // SnackBar informing the user that the service is unavailable.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    () async {
      try {
        await NotificationService().init();
      } catch (e, st) {
        debugPrint('NotificationService init failed: $e\n$st');
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('NotificationService不可用')),
        );
      }
    }();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => BackgroundMusicProvider()),
        ChangeNotifierProxyProvider2<
          StatisticsProvider,
          BackgroundMusicProvider,
          PomodoroProvider
        >(
          create: (_) => PomodoroProvider(),
          update: (_, stats, bgMusic, pomodoro) => pomodoro!
            ..setStatisticsProvider(stats)
            ..setBackgroundMusicProvider(bgMusic),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Todo Time Square',
            scaffoldMessengerKey: scaffoldMessengerKey,
            onGenerateTitle: (context) =>
                APPi18n.of(context)?.appTitle ?? 'Todo Time Square',
            locale: themeProvider.currentLocale,
            supportedLocales: const [
              Locale('zh', ''), // Chinese
              Locale('en', ''), // English
            ],
            localizationsDelegates: const [
              APPi18n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 25, 182, 221),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 25, 182, 221),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter, // 使用路由配置
            builder: (context, child) {
              final isDesktop = _isDesktopPlatform();
              final isTestEnv = _isTestEnvironment();
              if (isDesktop && !isTestEnv) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Scaffold(
                  body: Column(
                    children: [
                      WindowTitleBar(isDark: isDark),
                      Expanded(child: child!),
                    ],
                  ),
                );
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

bool _isDesktopPlatform() {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

bool _isTestEnvironment() {
  if (_kIsTestEnvironmentFlag) {
    return true;
  }
  if (kIsWeb) return false;
  try {
    return Platform.environment['FLUTTER_TEST'] == 'true';
  } catch (_) {
    return false;
  }
}

const bool _kIsTestEnvironmentFlag = bool.fromEnvironment(
  'FLUTTER_TEST',
  defaultValue: false,
);
