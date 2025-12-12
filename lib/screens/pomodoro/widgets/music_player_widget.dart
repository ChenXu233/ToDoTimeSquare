import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/background_music_provider.dart';
import 'music_import_widget.dart';

class MusicPlayerWidget extends StatefulWidget {
  final ValueNotifier<bool>? expandedNotifier;

  const MusicPlayerWidget({super.key, this.expandedNotifier});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  bool get isExpanded => _isExpanded;

  void collapse() {
    if (!mounted) return;
    setState(() {
      _isExpanded = false;
      widget.expandedNotifier?.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final track = provider.currentTrack;
        final title = track?.title ?? 'No Music Selected';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isExpanded ? 320 : 40,
          height: _isExpanded ? 260 : 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : 28),
          ),
          child: Material(
            color: Colors.transparent,
            child: _isExpanded
                ? _buildExpandedContent(context, provider, title)
                : _buildCollapsedContent(),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedContent() {
    return InkWell(
      onTap: () => setState(() {
        _isExpanded = true;
        widget.expandedNotifier?.value = true;
      }),
      borderRadius: BorderRadius.circular(28),
      child: const Center(
        child: Icon(Icons.music_note),
      ),
    );
  }

  Widget _buildExpandedContent(
      BuildContext context, BackgroundMusicProvider provider, String title) {
    final artist = provider.currentTrack?.artist ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header with Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                        content: const SizedBox(
                          width: double.maxFinite,
                          child: SingleChildScrollView(child: MusicImportWidget()),
                        ),
                      ),
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (artist.isNotEmpty)
                        Text(
                          artist,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
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
                        onChanged: (v) {
                          final newPos = duration * v;
                          provider.seekTo(newPos);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position), style: const TextStyle(fontSize: 10)),
                            Text(_formatDuration(duration), style: const TextStyle(fontSize: 10)),
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
                icon: Icon(_getModeIcon(provider.playbackMode)),
                onPressed: provider.togglePlaybackMode,
                tooltip: _getModeTooltip(provider.playbackMode),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: provider.playPrevious,
              ),
              IconButton(
                icon: Icon(provider.isBackgroundMusicPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled),
                onPressed: provider.toggleBackgroundMusic,
                iconSize: 48,
                color: Theme.of(context).primaryColor,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: provider.playNext,
              ),
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  _showVolumeDialog(context, provider);
                },
              ),
            ],
          ),
        ],
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

  String _getModeTooltip(MusicPlaybackMode mode) {
    switch (mode) {
      case MusicPlaybackMode.listLoop:
        return 'List Loop';
      case MusicPlaybackMode.shuffle:
        return 'Shuffle';
      case MusicPlaybackMode.radio:
        return 'Radio Mode';
    }
  }

  void _showVolumeDialog(BuildContext context, BackgroundMusicProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volume'),
        content: SizedBox(
          height: 200,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: provider.backgroundMusicVolume,
              onChanged: (v) => provider.setBackgroundMusicVolume(v),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

