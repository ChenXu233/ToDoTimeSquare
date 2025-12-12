import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/theme_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/glass/gradient_background.dart';
import 'widgets/duration_setting.dart';
import '../../widgets/glass/glass_dropdown.dart';

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
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: GlassDropdownFormField<Locale?>(
                              items: const [
                                DropdownMenuItem(
                                  value:
                                      null, // Null represents the "Auto" option
                                  child: Text('Auto'),
                                ),
                                DropdownMenuItem(
                                  value: Locale('en', ''),
                                  child: Text('English'),
                                ),
                                DropdownMenuItem(
                                  value: Locale('zh', ''),
                                  child: Text('中文'),
                                ),
                              ],
                              value: themeProvider.currentLocale,
                              onChanged: (Locale? newValue) {
                                themeProvider.changeLanguage(
                                  newValue,
                                ); // Handle null for "Auto"
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withAlpha(((0.3) * 255).round()),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_drop_down),
                              dropdownColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                            ),
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          leading: Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : (themeProvider.themeMode == ThemeMode.light
                                      ? Icons.light_mode
                                      : Icons.brightness_auto),
                          ),
                          title: Text(i18n.themeMode),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: GlassDropdownFormField<ThemeMode>(
                              items: [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text(i18n.themeSystem),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text(i18n.themeLight),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text(i18n.themeDark),
                                ),
                              ],
                              value: themeProvider.themeMode,
                              onChanged: (ThemeMode? newValue) {
                                if (newValue != null) {
                                  themeProvider.setThemeMode(newValue);
                                }
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withAlpha(((0.3) * 255).round()),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_drop_down),
                              dropdownColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
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
                        // 专注时间
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: DurationSetting(
                            title: i18n.focusTime,
                            value: pomodoroProvider.focusDuration ~/ 60,
                            onChanged: (newValue) {
                              pomodoroProvider.updateSettings(
                                focus: newValue * 60,
                              );
                            },
                            isDark: isDark,
                            sliderSize: 160,
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        // 短休息时间
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: DurationSetting(
                            title: i18n.shortBreak,
                            value: pomodoroProvider.shortBreakDuration ~/ 60,
                            onChanged: (newValue) {
                              pomodoroProvider.updateSettings(
                                shortBreak: newValue * 60,
                              );
                            },
                            isDark: isDark,
                            sliderSize: 160,
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        // 提示音
                        ListTile(
                          title: Text(i18n.alarmSound),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
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
                                              : (kIsWeb
                                                    ? pomodoroProvider
                                                          .alarmSoundPath
                                                          .split('/')
                                                          .last
                                                    : pomodoroProvider
                                                          .alarmSoundPath
                                                          .split(
                                                            Platform
                                                                .pathSeparator,
                                                          )
                                                          .last),
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
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  pomodoroProvider.setAlarmSound(
                                    'default',
                                  ); // Reset to default sound
                                },
                                tooltip: i18n.resetToDefault,
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
                          title: Text(i18n.reminderMode),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: GlassDropdownFormField<PomodoroReminderMode>(
                              items: [
                                DropdownMenuItem(
                                  value: PomodoroReminderMode.none,
                                  child: Text(i18n.reminderNone),
                                ),
                                DropdownMenuItem(
                                  value: PomodoroReminderMode.notification,
                                  child: Text(i18n.reminderNotification),
                                ),
                                DropdownMenuItem(
                                  value: PomodoroReminderMode.alarm,
                                  child: Text(i18n.reminderAlarm),
                                ),
                                DropdownMenuItem(
                                  value: PomodoroReminderMode.all,
                                  child: Text(i18n.reminderAll),
                                ),
                              ],
                              value: pomodoroProvider.reminderMode,
                              onChanged: (PomodoroReminderMode? newValue) {
                                if (newValue != null) {
                                  pomodoroProvider.updateSettings(
                                    reminderMode: newValue,
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withAlpha(((0.3) * 255).round()),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_drop_down),
                              dropdownColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                            ),
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          title: Text(i18n.autoPlayBackgroundMusic),
                          trailing: Switch(
                            value: pomodoroProvider.autoPlayBackgroundMusic,
                            onChanged: (v) =>
                                pomodoroProvider.setAutoPlayBackgroundMusic(v),
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
                            i18n.about,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            final version = snapshot.data?.version ?? '...';
                            return ListTile(
                              title: Text(i18n.version),
                              subtitle: Text('Todo Time Square v$version'),
                            );
                          },
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          title: Text('Todo Time Square'),
                          subtitle: Text('© 2025 ChenXu233'),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          subtitle: Text(
                            'Email: Woyerpa@outlook.com\nQQ: 1964324406\nGitHub: https://github.com/ChenXu233\n\n${i18n.somethingIWantToSay}',
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          title: Text(i18n.details),
                          subtitle: Text(i18n.appdetails),
                        ),
                      ],
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
