import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../widgets/error/error_view.dart';
import '../../../providers/background_music_provider.dart';
import 'music_import_widget.dart';
import '../../../i18n/i18n.dart';

class MusicPlayerWidget extends StatefulWidget {
  final ValueNotifier<bool>? expandedNotifier;

  const MusicPlayerWidget({super.key, this.expandedNotifier});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showVolumeBar = false;

  bool get isExpanded => _isExpanded;

  void collapse() {
    if (!mounted) return;
    setState(() {
      _isExpanded = false;
      _showVolumeBar = false;
      widget.expandedNotifier?.value = false;
    });
  }

  void _toggleVolumeBar() {
    setState(() => _showVolumeBar = !_showVolumeBar);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final track = provider.currentTrack;
        final title =
            track?.title ?? i18n?.noMusicSelected ?? 'No Music Selected';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isExpanded ? 320 : 40,
          height: _isExpanded
              ? (_showVolumeBar
                  ? (provider.hasError ? 320 : 280)
                  : (provider.hasError ? 260 : 220))
              : 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : 28),
          ),
          child: Material(
            color: Colors.transparent,
            child: _isExpanded
                ? _buildExpandedContent(
                    context,
                    provider,
                    title,
                    isMobile,
                    isDark,
                  )
                : _buildCollapsedContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedContent(bool isDark) {
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        return InkWell(
          onTap: () => setState(() {
            _isExpanded = true;
            widget.expandedNotifier?.value = true;
          }),
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: StreamBuilder<Duration>(
              stream: provider.backgroundMusicPositionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: provider.backgroundMusicDurationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    double progress = 0.0;
                    if (duration.inMilliseconds > 0) {
                      progress =
                          position.inMilliseconds / duration.inMilliseconds;
                      if (progress > 1.0) progress = 1.0;
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.5,
                            backgroundColor: isDark
                                ? Colors.white.withAlpha(76)
                                : Colors.black.withAlpha(76),
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Icon(
                          provider.isBackgroundMusicPlaying
                              ? Icons.music_note
                              : Icons.music_note_outlined,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    BackgroundMusicProvider provider,
    String title,
    bool isMobile,
    bool isDark,
  ) {
    final artist = provider.currentTrack?.artist ?? '';
    final i18n = APPi18n.of(context);
    final primaryColor = isDark ? Colors.white70 : Colors.black87;
    final secondaryColor = isDark ? Colors.white30 : Colors.black26;

    return GlassContainer(
      color: isDark ? Colors.black : Colors.white,
      opacity: 0.1,
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.playlist_add,
                      color: primaryColor,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          final rootContext =
                              Navigator.of(context, rootNavigator: true).context;
                          final dialogWidth =
                              MediaQuery.of(rootContext).size.width;
                          final isDialogMobile = dialogWidth < 600;
                          return GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Dialog(
                              backgroundColor: Colors.transparent,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {},
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isDialogMobile
                                          ? dialogWidth * 0.9
                                          : dialogWidth * 0.6,
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.85,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: MusicImportWidget(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artist.isNotEmpty)
                          Text(
                            artist,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      // 错误提示（紧凑模式）
                      if (provider.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: ErrorView(
                            errorType: provider.errorType,
                            message: provider.errorMessage,
                            recoveryAction: provider.recoveryAction,
                            showRetryButton: provider.canRetry,
                            onRetry: provider.retryAfterError,
                            onDismiss: provider.clearError,
                            isDark: isDark,
                            compact: true,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: primaryColor),
                  onPressed: () => collapse(),
                ),
              ],
            ),
          ),

          // Progress Bar & Time
          StreamBuilder<Duration>(
            stream: provider.backgroundMusicPositionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: provider.backgroundMusicDurationStream,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  double value = 0.0;
                  if (duration.inMilliseconds > 0) {
                    value = position.inMilliseconds / duration.inMilliseconds;
                    if (value > 1.0) value = 1.0;
                  }

                  return Column(
                    children: [
                      Slider(
                        value: value,
                        activeColor: primaryColor,
                        inactiveColor: secondaryColor,
                        onChanged: (v) {
                          final newPos = duration * v;
                          provider.seekTo(newPos);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _getModeIcon(provider.playbackMode),
                  color: primaryColor,
                ),
                onPressed: provider.togglePlaybackMode,
                tooltip: _getModeTooltip(provider.playbackMode, i18n),
              ),
              IconButton(
                icon: Icon(Icons.skip_previous, color: primaryColor),
                onPressed: provider.playPrevious,
              ),
              IconButton(
                icon: Icon(
                  provider.isBackgroundMusicPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: primaryColor,
                ),
                onPressed: provider.toggleBackgroundMusic,
                iconSize: 48,
              ),
              IconButton(
                icon: Icon(Icons.skip_next, color: primaryColor),
                onPressed: provider.playNext,
              ),
              GestureDetector(
                onTap: _toggleVolumeBar,
                child: Icon(
                  _getVolumeIcon(provider.backgroundMusicVolume),
                  color: _showVolumeBar ? primaryColor : primaryColor.withOpacity(0.5),
                ),
              ),
            ],
          ),

          // Volume Bar (底部，可折叠)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 50),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                );
              },
              child: _showVolumeBar
                  ? Column(
                      key: const ValueKey('volumeBar'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(
                                _getVolumeIcon(provider.backgroundMusicVolume),
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Slider(
                                  value: provider.backgroundMusicVolume,
                                  activeColor: primaryColor,
                                  inactiveColor: secondaryColor,
                                  onChanged: provider.setBackgroundMusicVolume,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(provider.backgroundMusicVolume * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ],
      ),
    ),
  );
}

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  IconData _getModeIcon(MusicPlaybackMode mode) {
    switch (mode) {
      case MusicPlaybackMode.listLoop:
        return Icons.repeat;
      case MusicPlaybackMode.shuffle:
        return Icons.shuffle;
      case MusicPlaybackMode.radio:
        return Icons.radio;
    }
  }

  String _getModeTooltip(MusicPlaybackMode mode, APPi18n? i18n) {
    switch (mode) {
      case MusicPlaybackMode.listLoop:
        return i18n?.listLoop ?? 'List Loop';
      case MusicPlaybackMode.shuffle:
        return i18n?.shuffle ?? 'Shuffle';
      case MusicPlaybackMode.radio:
        return i18n?.radioMode ?? 'Radio Mode';
    }
  }

  IconData _getVolumeIcon(double volume) {
    if (volume == 0) return Icons.volume_off;
    if (volume < 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }
}
