import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart'; // 导入路由配置
import 'i18n/i18n.dart'; // 导入生成的国际化文件

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          return MaterialApp.router(
            title: APPi18n.of(context)?.appTitle ?? 'Todo Time Square',
            locale: appState.currentLocale,
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('zh', ''), // Chinese
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
            themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: appRouter, // 使用路由配置
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  bool _darkMode = false;
  Locale _currentLocale = const Locale('en', '');

  bool get darkMode => _darkMode;
  Locale get currentLocale => _currentLocale;

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void changeLanguage(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }
}
