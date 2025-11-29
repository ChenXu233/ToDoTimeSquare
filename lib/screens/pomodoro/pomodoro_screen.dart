import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass_container.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  bool _isFullScreen = false;

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showInfoDialog(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Dialog(
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
                i18n.pomodoroInfo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                i18n.pomodoroInfoContent,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(i18n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int focus = provider.focusDuration ~/ 60;
    int short = provider.shortBreakDuration ~/ 60;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
                  _buildDurationSetting(
                    i18n.focusTime, 
                    focus, 
                    (val) => setState(() => focus = val),
                    isDark
                  ),
                  const SizedBox(height: 16),
                  _buildDurationSetting(
                    i18n.shortBreak, 
                    short, 
                    (val) => setState(() => short = val),
                    isDark
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
        }
      ),
    );
  }

  Widget _buildDurationSetting(String label, int value, Function(int) onChanged, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(((0.1)*255).round()) : Colors.black.withAlpha(((0.05)*255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white.withAlpha(((0.2)*255).round()) : Colors.black.withAlpha(((0.1)*255).round())),
          ),
          child: DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            items: [5, 10, 15, 20, 25, 30, 45, 60].map((e) => DropdownMenuItem(value: e, child: Text('$e min'))).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        // Dynamic background color based on status
        Color bgColor;
        Color fgColor;
        
        switch (provider.status) {
          case PomodoroStatus.focus:
            bgColor = isDark ? Colors.black : Colors.white;
            fgColor = isDark ? Colors.white : Colors.black;
            break;
          case PomodoroStatus.shortBreak:
            bgColor = isDark ? const Color(0xFF1A2E22) : const Color(0xFFE8F5E9);
            fgColor = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
            break;
        }

        if (provider.isRinging) {
           bgColor = Colors.redAccent;
           fgColor = Colors.white;
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status Text (Small)
                      Text(
                      provider.isRinging ? "TIME'S UP!" : (provider.status == PomodoroStatus.focus ? i18n.pomodoroStatusFocus : i18n.pomodoroStatusShortBreak).toUpperCase(),
                      style: TextStyle(
                        color: fgColor.withAlpha(((0.6)*255).round()),
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Huge Timer
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatTime(provider.remainingSeconds),
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Progress Bar (Thin line)
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: fgColor.withAlpha(((0.1)*255).round()),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: provider.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: fgColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Minimal Controls
                    if (provider.isRinging)
                       ElevatedButton(
                        onPressed: provider.stopAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text("STOP ALARM", style: TextStyle(fontWeight: FontWeight.bold)),
                       )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: provider.resetTimer,
                            icon: const Icon(Icons.refresh),
                            color: fgColor.withAlpha(((0.5)*255).round()),
                            iconSize: 24,
                          ),
                          const SizedBox(width: 40),
                          IconButton(
                            onPressed: provider.isRunning ? provider.pauseTimer : provider.startTimer,
                            icon: Icon(provider.isRunning ? Icons.pause : Icons.play_arrow),
                            color: fgColor,
                            iconSize: 48,
                          ),
                          const SizedBox(width: 40),
                          IconButton(
                            onPressed: () => _showSettingsDialog(context),
                            icon: const Icon(Icons.settings),
                            color: fgColor.withAlpha(((0.5)*255).round()),
                            iconSize: 24,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Top Bar (Back & Fullscreen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: fgColor,
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                          color: fgColor,
                          onPressed: _toggleFullScreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Info Button (Bottom Right)
              Positioned(
                bottom: 32,
                right: 32,
                child: IconButton(
                  icon: const Icon(Icons.info_outline),
                  color: fgColor.withAlpha((0.5 * 255).round()),
                  onPressed: () => _showInfoDialog(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




