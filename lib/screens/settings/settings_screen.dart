import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/theme_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/background_music_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_settings_provider.dart';
import '../../providers/ai_settings_provider.dart';
import '../../services/sync_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/sync/conflict_resolve_dialog.dart';
import '../../i18n/i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/glass/glass_container.dart';
import '../../models/database/database_initializer.dart';
import 'components/export_data_dialog.dart';
import '../../widgets/glass/gradient_background.dart';
import 'components/consistent_icon.dart';
import 'components/duration_setting.dart';
import '../../widgets/glass/glass_dropdown.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Future<void> _showApiKeyDialog(BuildContext context, AISettingsProvider aiProvider) async {
    final controller = TextEditingController(text: aiProvider.apiKey);
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claude API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '用于 AI 任务分析和优化功能',
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(((0.6) * 255).round()),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-ant-api...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await aiProvider.setApiKey(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

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
                  // User avatar section
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isLoggedIn = authProvider.isLoggedIn;
                      final user = authProvider.currentUser;

                      return GlassContainer(
                        color: isDark ? Colors.black : Colors.white,
                        opacity: 0.1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Icon(
                              isLoggedIn ? Icons.person : Icons.person_outline,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            isLoggedIn && user != null
                                ? user.username
                                : i18n.tapToLogin,
                          ),
                          subtitle: Text(
                            isLoggedIn && user != null
                                ? user.email
                                : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isLoggedIn
                              ? IconButton(
                                  icon: const Icon(Icons.logout),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(i18n.logoutConfirmTitle),
                                        content: Text(i18n.logoutConfirmMessage),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(i18n.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await authProvider.logout();
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                              }
                                            },
                                            child: Text(i18n.logout),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : null,
                          onTap: isLoggedIn
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LoginScreen(),
                                    ),
                                  );
                                },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassContainer(
                    color: isDark ? Colors.black : Colors.white,
                    opacity: 0.1,
                    child: Column(
                      children: [
                        ListTile(
                          leading: ConsistentIcon(Icons.language),
                          title: Text(i18n.language),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: GlassDropdownFormField<Locale?>(
                              items: [
                                DropdownMenuItem(
                                  value:
                                      null, // Null represents the "Auto" option
                                  child: Text(i18n.languageAuto),
                                ),
                                DropdownMenuItem(
                                  value: Locale('en', ''),
                                  child: Text(i18n.languageEnglish),
                                ),
                                DropdownMenuItem(
                                  value: Locale('zh', ''),
                                  child: Text(i18n.languageChinese),
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
                        ListTile(
                          leading: ConsistentIcon(
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
                  //cache settings
                  GlassContainer(
                    color: isDark ? Colors.black : Colors.white,
                    opacity: 0.1,
                    child: Column(
                      children: [
                        // Music cache settings
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            i18n.musicCache,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Consumer<BackgroundMusicProvider>(
                          builder: (context, musicProvider, child) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<int>(
                                    future: musicProvider.getCacheSize(),
                                    builder: (context, snap) {
                                      final size = snap.data ?? 0;
                                      return Text(
                                        '${i18n.currentCache} ${(size / 1024 / 1024).toStringAsFixed(2)} MB',
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue:
                                              (musicProvider.cacheMaxBytes ~/
                                                      (1024 * 1024))
                                                  .toString(),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: i18n.maxCacheMb,
                                          ),
                                          onFieldSubmitted: (v) async {
                                            final mb = int.tryParse(v) ?? 200;
                                            await musicProvider
                                                .setCacheMaxBytes(
                                                  mb * 1024 * 1024,
                                                );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  i18n.cacheMaxUpdated,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await musicProvider.clearCache();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(i18n.cacheCleared),
                                            ),
                                          );
                                        },
                                        child: Text(i18n.clearCache),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            );
                          },
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
                            sliderSize: 145,
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
                            sliderSize: 145,
                          ),
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        // 提示音
                        ListTile(
                          leading: ConsistentIcon(Icons.volume_up),
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
                        // 提示方式
                        ListTile(
                          leading: ConsistentIcon(Icons.notifications),
                          title: Text(i18n.reminderMode),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
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
                          leading: ConsistentIcon(Icons.music_note),
                          title: Text(i18n.autoPlayBackgroundMusic),
                          subtitle: Text(i18n.autoPlayBackgroundMusicSubtitle),
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
                  // Data Management Section
                  GlassContainer(
                    color: isDark ? Colors.black : Colors.white,
                    opacity: 0.1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ConsistentIcon(Icons.storage),
                              const SizedBox(width: 12),
                              Text(
                                i18n.dataManagement,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).dividerColor.withAlpha(((0.1) * 255).round()),
                        ),
                        ListTile(
                          leading: ConsistentIcon(Icons.download),
                          title: Text(i18n.exportData),
                          subtitle: Text(i18n.exportDataDescription),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final db = DatabaseInitializer().database;
                            showExportDataDialog(context, db);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // AI Settings Section
                  Consumer<AISettingsProvider>(
                    builder: (context, aiProvider, child) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;

                      return GlassContainer(
                        color: isDark ? Colors.black : Colors.white,
                        opacity: 0.1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  ConsistentIcon(Icons.auto_awesome),
                                  const SizedBox(width: 12),
                                  Text(
                                    'AI 设置',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: Theme.of(context).dividerColor.withAlpha(((0.1) * 255).round()),
                            ),
                            ListTile(
                              leading: ConsistentIcon(Icons.key),
                              title: const Text('Claude API Key'),
                              subtitle: Text(
                                aiProvider.hasApiKey
                                    ? '${aiProvider.apiKey.substring(0, 8)}...'
                                    : '未配置',
                              ),
                              trailing: Icon(
                                aiProvider.hasApiKey
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                color: aiProvider.hasApiKey
                                    ? Colors.green[400]
                                    : Colors.orange[400],
                              ),
                              onTap: () => _showApiKeyDialog(context, aiProvider),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Sync Settings Section
                  Consumer<SyncSettingsProvider>(
                    builder: (context, syncProvider, child) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;

                      return GlassContainer(
                        color: isDark ? Colors.black : Colors.white,
                        opacity: 0.1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  ConsistentIcon(Icons.sync),
                                  const SizedBox(width: 12),
                                  Text(
                                    i18n.syncSettings,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: Theme.of(context).dividerColor.withAlpha(((0.1) * 255).round()),
                            ),
                            // Server URL input
                            ListTile(
                              leading: ConsistentIcon(Icons.link),
                              title: Text(i18n.serverUrl),
                              subtitle: Text(syncProvider.serverUrl),
                              trailing: SizedBox(
                                width: 200,
                                child: TextFormField(
                                  initialValue: syncProvider.serverUrl,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: (isDark ? Colors.white : Colors.black)
                                            .withAlpha(((0.3) * 255).round()),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    errorText: syncProvider.errorMessage,
                                  ),
                                  onChanged: (value) {
                                    syncProvider.setServerUrl(value);
                                    AuthServiceConfig.updateBaseUrl(value);
                                  },
                                ),
                              ),
                            ),
                            Divider(
                              color: Theme.of(context).dividerColor.withAlpha(((0.1) * 255).round()),
                            ),
                            // Auto sync toggle
                            ListTile(
                              leading: ConsistentIcon(Icons.autorenew),
                              title: Text(i18n.autoSync),
                              subtitle: Text(i18n.autoSyncDescription),
                              trailing: Switch(
                                value: syncProvider.autoSync,
                                onChanged: (value) =>
                                    syncProvider.setAutoSync(value),
                              ),
                            ),
                            Divider(
                              color: Theme.of(context).dividerColor.withAlpha(((0.1) * 255).round()),
                            ),
                            // Start sync button (style like other buttons)
                            Consumer2<AuthProvider, SyncService>(
                              builder: (context, authProvider, syncService, child) {
                                final isLoggedIn = authProvider.isLoggedIn;
                                return ListTile(
                                  leading: ConsistentIcon(Icons.sync),
                                  title: Text(
                                    isLoggedIn
                                        ? i18n.startSync
                                        : i18n.syncRequiresLogin,
                                  ),
                                  subtitle: syncService.progressState == SyncProgressState.uploading ||
                                          syncService.progressState == SyncProgressState.downloading
                                      ? Text(syncService.totalRecords > 0
                                          ? '${i18n.syncing} ${syncService.processedRecords}/${syncService.totalRecords}'
                                          : i18n.syncing)
                                      : syncProvider.lastSyncTimeFormatted != null
                                          ? Text('${i18n.lastSync}: ${syncProvider.lastSyncTimeFormatted}')
                                          : null,
                                  trailing: syncProvider.isSyncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : syncProvider.hasConflicts
                                          ? const Icon(Icons.warning, color: Colors.orange)
                                          : const Icon(Icons.chevron_right),
                                  onTap: syncProvider.isSyncing
                                      ? null
                                      : () async {
                                          if (!isLoggedIn) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(i18n.syncRequiresLogin),
                                              ),
                                            );
                                            return;
                                          }
                                          await syncProvider.startSync(context);
                                        },
                                );
                              },
                            ),
                            // Last sync result
                            if (syncProvider.lastSyncResult != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  '${i18n.lastSyncResult}: ${syncProvider.lastSyncResult}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            // Conflicts list
                            if (syncProvider.hasConflicts)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    color: Theme.of(context).dividerColor.withAlpha(((0.1) * 255).round()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${syncProvider.conflictCount} ${i18n.resolveConflict}',
                                          style: TextStyle(
                                            color: isDark ? Colors.orange[200] : Colors.orange[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...syncProvider.conflicts.map((conflict) {
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.compare_arrows, size: 20),
                                      title: Text('${_getEntityTypeName(context, conflict.entityType)} (${conflict.entityId.substring(0, 8)}...)'),
                                      subtitle: Text('v${conflict.localVersion} vs v${conflict.serverVersion}'),
                                      trailing: const Icon(Icons.chevron_right, size: 20),
                                      onTap: () async {
                                        final auth = Provider.of<AuthProvider>(context, listen: false);
                                        if (!auth.isLoggedIn || auth.accessToken == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(i18n.syncRequiresLogin)),
                                          );
                                          return;
                                        }
                                        final resolved = await showConflictResolveDialog(
                                          context,
                                          conflict,
                                          auth.accessToken!,
                                        );
                                        if (resolved == true) {
                                          syncProvider.clearConflicts();
                                        }
                                      },
                                    );
                                  }),
                                ],
                              ),
                            // Large data warning (Web only)
                            if (syncProvider.showLargeDataWarning)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(50),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withAlpha(100),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue[700]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              i18n.largeDataWarningTitle,
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              i18n.largeDataWarningMessage,
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Full sync button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: OutlinedButton.icon(
                                onPressed: syncProvider.isSyncing
                                    ? null
                                    : () async {
                                        final i18n = APPi18n.of(context)!;
                                        await syncProvider.resetSyncTimestamp();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(i18n.syncTimestampReset),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text(i18n.fullSync),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  GlassContainer(
                    color: isDark ? Colors.black : Colors.white,
                    opacity: 0.1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reset all settings button
                        ListTile(
                          leading: ConsistentIcon(Icons.restore),
                          title: Text(i18n.resetAllSettings),
                          subtitle: Text(i18n.resetAllSettingsDescription),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(i18n.resetAllSettings),
                                content: Text(i18n.resetAllSettingsConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(i18n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final navigatorContext = context;
                                      if (!navigatorContext.mounted) return;

                                      // Save providers before async operations
                                      final themeProvider =
                                          Provider.of<ThemeProvider>(navigatorContext,
                                              listen: false);
                                      final pomodoroProvider =
                                          Provider.of<PomodoroProvider>(navigatorContext,
                                              listen: false);
                                      final syncProvider =
                                          Provider.of<SyncSettingsProvider>(navigatorContext,
                                              listen: false);

                                      // Reset theme
                                      await themeProvider.setThemeMode(ThemeMode.system);
                                      await themeProvider.changeLanguage(null);

                                      // Reset pomodoro
                                      pomodoroProvider.updateSettings(
                                        focus: 25 * 60,
                                        shortBreak: 5 * 60,
                                      );

                                      // Reset sync
                                      await syncProvider.resetSyncSettings();
                                      AuthServiceConfig.resetBaseUrl();

                                      if (!navigatorContext.mounted) return;
                                      Navigator.pop(navigatorContext);
                                      ScaffoldMessenger.of(navigatorContext).showSnackBar(
                                        SnackBar(
                                          content: Text(i18n.settingsResetSuccess),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      i18n.confirm,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
                        ListTile(
                          leading: ConsistentIcon(Icons.code),
                          title: Text(i18n.sourceCode),
                          subtitle: const Text('https://github.com/ChenXu233'),
                          onTap: () async {
                            final uri = Uri.parse(
                              'https://github.com/ChenXu233',
                            );
                            try {
                              if (!await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              )) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(i18n.couldNotOpenUrl),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(i18n.couldNotOpenUrl),
                                ),
                              );
                            }
                          },
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

  String _getEntityTypeName(BuildContext context, String entityType) {
    final i18n = APPi18n.of(context)!;
    switch (entityType) {
      case 'todo':
        return i18n.entityTodo;
      case 'focus_record':
        return i18n.entityFocusRecord;
      case 'habit':
        return i18n.entityHabit;
      case 'habit_log':
        return i18n.entityHabitLog;
      case 'tag':
        return i18n.entityTag;
      case 'tag_relation':
        return i18n.entityTagRelation;
      default:
        return entityType;
    }
  }
}


