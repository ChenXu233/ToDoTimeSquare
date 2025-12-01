import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/theme_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/gradient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final pomodoroProvider = Provider.of<PomodoroProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(i18n.settings),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlassContainer(
                    color: isDark ? Colors.black : Colors.white,
                    opacity: 0.1,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: Text(i18n.language),
                          trailing: DropdownButton<Locale>(
                            value: themeProvider.currentLocale,
                            underline: const SizedBox(),
                            dropdownColor: isDark
                                ? Colors.grey[900]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            onChanged: (Locale? newValue) {
                              if (newValue != null) {
                                themeProvider.changeLanguage(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: Locale('en', ''),
                                child: Text('English'),
                              ),
                              DropdownMenuItem(
                                value: Locale('zh', ''),
                                child: Text('中文'),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          leading: Icon(
                            themeProvider.darkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: Text(i18n.darkMode),
                          trailing: Switch(
                            value: themeProvider.darkMode,
                            onChanged: (value) {
                              themeProvider.toggleDarkMode();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassContainer(
                    color: isDark ? Colors.black : Colors.white,
                    opacity: 0.1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            i18n.pomodoroSettings,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ListTile(
                          title: Text(i18n.focusTime),
                          trailing: DropdownButton<int>(
                            value: pomodoroProvider.focusDuration ~/ 60,
                            underline: const SizedBox(),
                            dropdownColor: isDark
                                ? Colors.grey[900]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                pomodoroProvider.updateSettings(
                                  focus: newValue * 60,
                                );
                              }
                            },
                            items: [5, 10, 15, 20, 25, 30, 45, 60]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('$e min'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          title: Text(i18n.shortBreak),
                          trailing: DropdownButton<int>(
                            value: pomodoroProvider.shortBreakDuration ~/ 60,
                            underline: const SizedBox(),
                            dropdownColor: isDark
                                ? Colors.grey[900]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                pomodoroProvider.updateSettings(
                                  shortBreak: newValue * 60,
                                );
                              }
                            },
                            items: [5, 10, 15, 20, 25, 30, 45, 60]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('$e min'),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          title: Text(i18n.alarmSound),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: InkWell(
                              onTap: () async {
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(type: FileType.audio);

                                if (result != null &&
                                    result.files.single.path != null) {
                                  pomodoroProvider.setAlarmSound(
                                    result.files.single.path!,
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      pomodoroProvider.alarmSoundPath
                                              .startsWith('http')
                                          ? 'Default'
                                          : pomodoroProvider.alarmSoundPath
                                                .split(Platform.pathSeparator)
                                                .last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassContainer(
                    color: isDark ? Colors.black : Colors.white,
                    opacity: 0.1,
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(i18n.about),
                      subtitle: const Text('Todo Time Square v0.0.1'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
