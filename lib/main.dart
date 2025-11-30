import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart'; // 导入路由配置
import 'i18n/i18n.dart'; // 导入生成的国际化文件
import 'providers/theme_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/todo_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Error setting high refresh rate: $e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Todo Time Square',
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
            themeMode: themeProvider.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            routerConfig: appRouter, // 使用路由配置
          );
        },
      ),
    );
  }
}
