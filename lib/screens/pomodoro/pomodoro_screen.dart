import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/todo_provider.dart';
import '../../i18n/i18n.dart';
import '../../models/todo.dart';
import 'widgets/task_tray.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/info_dialog.dart';
import 'widgets/completion_dialog.dart';
import 'widgets/music_player_widget.dart';

class PomodoroScreen extends StatefulWidget {
  final Todo? initialTask;

  const PomodoroScreen({super.key, this.initialTask});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  bool _isFullScreen = false;
  late final ConfettiController _confettiController;
  bool _isTaskExpanded = false;
  final GlobalKey _musicKey = GlobalKey();
  final ValueNotifier<bool> _musicExpanded = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PomodoroProvider>();
      if (widget.initialTask != null) {
        bool changed = provider.setTask(
          id: widget.initialTask!.id,
          title: widget.initialTask!.title,
        );
        if (changed) {
          provider.startTimer();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant PomodoroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTask?.id != oldWidget.initialTask?.id) {
      if (widget.initialTask != null) {
        final provider = context.read<PomodoroProvider>();
        bool changed = provider.setTask(
          id: widget.initialTask!.id,
          title: widget.initialTask!.title,
        );
        if (changed) {
          provider.startTimer();
        }
      }
    }
  }

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
    _confettiController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _musicExpanded.dispose();
    super.dispose();
  }

  Todo? _getActiveTask(BuildContext context, PomodoroProvider provider) {
    final taskId = provider.currentTaskId;
    if (taskId == null) return null;
    try {
      return context.watch<TodoProvider>().todos.firstWhere(
        (t) => t.id == taskId,
      );
    } catch (e) {
      return null;
    }
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _completeActiveTask(BuildContext context) async {
    final provider = context.read<PomodoroProvider>();
    final taskId = provider.currentTaskId;
    if (taskId == null) return;

    await context.read<TodoProvider>().markTodoCompleted(taskId);
    if (!mounted) return;

    provider.resetTimer(clearTask: true);
    setState(() {
      _isTaskExpanded = false;
    });
    _confettiController.play();
    await showPomodoroCompletionDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontPreloader = Text(
      "1234567890",
      style: TextStyle(
        fontSize: 120,
        fontWeight: FontWeight.w900,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    fontPreloader; // Prevent unused variable warning

    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        final activeTask = _getActiveTask(context, provider);
        // Dynamic background color based on status
        Color bgColor;
        Color fgColor;

        switch (provider.status) {
          case PomodoroStatus.focus:
            bgColor = isDark ? Colors.black : Colors.white;
            fgColor = isDark ? Colors.white : Colors.black;
            break;
          case PomodoroStatus.shortBreak:
            bgColor = isDark
                ? const Color(0xFF1A2E22)
                : const Color(0xFFE8F5E9);
            fgColor = isDark
                ? const Color(0xFFA5D6A7)
                : const Color(0xFF2E7D32);
            break;
        }

        if (provider.isRinging) {
          bgColor = Colors.redAccent;
          fgColor = Colors.white;
        }

        // Responsive: treat narrow screens as "mobile" style.
        final isMobile = MediaQuery.of(context).size.width < 490;

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
                      provider.isRinging
                          ? "TIME'S UP!"
                          : (provider.status == PomodoroStatus.focus
                                    ? i18n.pomodoroStatusFocus
                                    : i18n.pomodoroStatusShortBreak)
                                .toUpperCase(),
                      style: TextStyle(
                        color: fgColor.withAlpha(((0.6) * 255).round()),
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
                        color: fgColor.withAlpha(((0.1) * 255).round()),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          "STOP ALARM",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    provider.resetTimer(clearTask: true),
                                icon: const Icon(Icons.refresh),
                                color: fgColor.withAlpha(((0.5) * 255).round()),
                                iconSize: 24,
                              ),
                              const SizedBox(width: 40),
                              IconButton(
                                onPressed: provider.isRunning
                                    ? provider.pauseTimer
                                    : provider.startTimer,
                                icon: Icon(
                                  provider.isRunning
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                color: fgColor,
                                iconSize: 48,
                              ),
                              const SizedBox(width: 40),
                              IconButton(
                                onPressed: provider.skipPhase,
                                icon: const Icon(Icons.skip_next),
                                color: fgColor.withAlpha(((0.5) * 255).round()),
                                iconSize: 24,
                              ),
                            ],
                          ),
                          if (activeTask != null) ...[
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _completeActiveTask(context),
                              icon: const Icon(Icons.celebration),
                              label: Text(i18n.completeTask),
                              style: FilledButton.styleFrom(
                                backgroundColor: fgColor,
                                foregroundColor: bgColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: fgColor,
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                          ),
                          color: fgColor,
                          onPressed: _toggleFullScreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Info Button (Bottom Left)
              Positioned(
                bottom: 32,
                left: 32,
                child: IconButton(
                  icon: const Icon(Icons.info_outline),
                  color: fgColor.withAlpha((0.5 * 255).round()),
                  onPressed: () => showPomodoroInfoDialog(context),
                ),
              ),

              // Settings Button (Bottom Right)
              Positioned(
                bottom: 32,
                right: 32,
                child: IconButton(
                  onPressed: () => showPomodoroSettingsDialog(context),
                  icon: const Icon(Icons.settings),
                  color: fgColor.withAlpha(((0.5) * 255).round()),
                ),
              ),

              // Music Player Widget (top center) with outside-tap collapse
              ValueListenableBuilder<bool>(
                valueListenable: _musicExpanded,
                builder: (context, expanded, child) {
                  return Stack(
                    children: [
                      if (expanded)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              try {
                                (_musicKey.currentState as dynamic).collapse();
                              } catch (_) {}
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                      Positioned(
                        bottom: 100,
                        right: 32,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: MusicPlayerWidget(
                            key: _musicKey,
                            expandedNotifier: _musicExpanded,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Task Tray (Bottom)
              if (activeTask != null && _isTaskExpanded)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _isTaskExpanded = false),
                  ),
                ),
              if (activeTask != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TaskTray(
                    task: activeTask,
                    isExpanded: _isTaskExpanded,
                    fgColor: fgColor,
                    bgColor: bgColor,
                    isDark: isDark,
                    theme: theme,
                    i18n: i18n,
                    onExpand: () => setState(() => _isTaskExpanded = true),
                    showMeta: !isMobile,
                  ),
                ),
              // Confetti Widget
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 35,
                  maxBlastForce: 20,
                  minBlastForce: 5,
                  gravity: 0.4,
                  emissionFrequency: 0.02,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
