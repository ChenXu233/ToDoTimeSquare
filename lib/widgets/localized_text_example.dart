import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/i18n.dart';
import '../providers/theme_provider.dart';

class LocalizedTextExample extends StatelessWidget {
  const LocalizedTextExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取本地化文本
    final i18n = APPi18n.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n?.appTitle ?? 'App Title'),
        actions: [
          // 语言切换按钮
          DropdownButton<Locale>(
            value: themeProvider.currentLocale,
            icon: const Icon(Icons.language),
            onChanged: (Locale? newValue) {
              if (newValue != null) {
                themeProvider.changeLanguage(newValue);
              }
            },
            items: const [
              DropdownMenuItem(value: Locale('en', ''), child: Text('English')),
              DropdownMenuItem(value: Locale('zh', ''), child: Text('中文')),
            ],
          ),
          // 暗黑模式切换
          Switch(
            value: themeProvider.darkMode,
            onChanged: (value) {
              themeProvider.toggleDarkMode();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              i18n?.welcomeMessage ?? 'Welcome message',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 示例按钮操作
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(i18n?.addTask ?? 'Add Task')),
                );
              },
              child: Text(i18n?.addTask ?? 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
