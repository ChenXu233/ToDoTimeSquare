import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../screens/settings/widgets/duration_setting.dart';

Future<void> showPomodoroSettingsDialog(BuildContext context) {
  final provider = Provider.of<PomodoroProvider>(context, listen: false);
  final i18n = APPi18n.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  int focus = provider.focusDuration ~/ 60;
  int short = provider.shortBreakDuration ~/ 60;

  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            color: isDark ? Colors.black : Colors.white,
            opacity: 0.1,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.settings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                DurationSetting(
                  title: i18n.focusTime,
                  value: focus,
                  onChanged: (val) => setState(() => focus = val),
                  isDark: isDark,
                  showsSlider: isMobile ? false : true,
                ),
                const SizedBox(height: 16),
                DurationSetting(
                  title: i18n.shortBreak,
                  value: short,
                  onChanged: (val) => setState(() => short = val),
                  isDark: isDark,
                  showsSlider: isMobile ? false : true,
                ),
                const SizedBox(height: 24),
                Text(i18n.alarmSound, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Consumer<PomodoroProvider>(
                  builder: (context, provider, _) {
                    final path = provider.alarmSoundPath;
                    final name = path.startsWith('http')
                        ? 'Default'
                        : (kIsWeb
                              ? path.split('/').last
                              : path.split(Platform.pathSeparator).last);
                    return InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.audio);

                        if (result != null && result.files.single.path != null) {
                          provider.setAlarmSound(result.files.single.path!);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(((0.1) * 255).round())
                              : Colors.black.withAlpha(((0.05) * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withAlpha(((0.2) * 255).round())
                                : Colors.black.withAlpha(((0.1) * 255).round()),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(i18n.cancel),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () {
                        provider.updateSettings(
                          focus: focus * 60,
                          shortBreak: short * 60,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(i18n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
