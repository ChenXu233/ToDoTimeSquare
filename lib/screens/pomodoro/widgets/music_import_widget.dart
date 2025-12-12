import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/background_music_provider.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../i18n/i18n.dart';
import 'music_list_components.dart';

class MusicImportWidget extends StatefulWidget {
  const MusicImportWidget({super.key});

  @override
  State<MusicImportWidget> createState() => _MusicImportWidgetState();
}

class _MusicImportWidgetState extends State<MusicImportWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final i18n = APPi18n.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.hasBoundedWidth && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width * 0.5;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: availableWidth),
          child: GlassContainer(
            color: isDark ? Colors.black : Colors.white,
            opacity: 0.1,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      i18n?.musicLibrary ?? 'Music Library',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: () {
                        final provider = context
                            .read<BackgroundMusicProvider>();
                        provider.fetchDefaultTracks();
                        provider.fetchRadioTracks();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: isDark ? Colors.white70 : Colors.black87,
                  unselectedLabelColor: isDark
                      ? Colors.white60
                      : Colors.black54,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: [
                    Tab(
                      text: i18n?.localTab ?? 'Local',
                      icon: Icon(
                        Icons.folder,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Tab(
                      text: i18n?.defaultTab ?? 'Default',
                      icon: Icon(
                        Icons.music_note,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Tab(
                      text: i18n?.radioTab ?? 'Radio',
                      icon: Icon(
                        Icons.radio,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLocalList(context, isDark),
                      _buildDefaultList(context, isDark),
                      _buildRadioList(context, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalList(BuildContext context, bool isDark) {
    final i18n = APPi18n.of(context);
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.playlist;
        if (tracks.isEmpty) {
          return EmptyState(
            message: i18n?.noLocalMusicImported ?? 'No local music imported',
            buttonText: i18n?.importFromDevice ?? 'Import from Device',
            onButton: () => provider.importMusic(),
            isDark: isDark,
          );
        }
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => provider.importMusic(),
                icon: Icon(
                  Icons.add,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                label: Text(
                  i18n?.addMore ?? 'Add More',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(right: 10, left: 10),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isPlaying = provider.currentTrack?.id == track.id;
                  return TrackTile(
                    track: track,
                    isPlaying: isPlaying,
                    isDark: isDark,
                    leadingIcon: isPlaying ? Icons.music_note : Icons.music_off,
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      onPressed: () => provider.removeTrack(track),
                    ),
                    onTap: () => provider.playTrack(track),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultList(BuildContext context, bool isDark) {
    final i18n = APPi18n.of(context);
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.defaultTracks;
        if (provider.isLoadingMusic) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          );
        }
        if (tracks.isEmpty) {
          return EmptyState(
            message: i18n?.noDefaultTracks ?? 'No default tracks available',
            isDark: isDark,
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(right: 10, left: 10),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isDownloaded = track.isLocal || track.localPath != null;
            final isPlaying = provider.currentTrack?.id == track.id;
            return TrackTile(
              track: track,
              isPlaying: isPlaying,
              isDark: isDark,
              leadingIcon: isPlaying
                  ? Icons.play_circle_filled
                  : Icons.music_note,
              trailing: isDownloaded
                  ? IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      onPressed: () => provider.removeTrack(track),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.download,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      onPressed: () => provider.downloadTrack(track),
                    ),
              onTap: () => provider.playTrack(track),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioList(BuildContext context, bool isDark) {
    final i18n = APPi18n.of(context);
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.radioTracks;
        if (tracks.isEmpty) {
          return EmptyState(
            message:
                i18n?.noRadioStationsAvailable ?? 'No radio stations available',
            isDark: isDark,
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(right: 10, left: 10),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isPlaying = provider.currentTrack?.id == track.id;
            return TrackTile(
              track: track,
              isPlaying: isPlaying,
              isDark: isDark,
              leadingIcon: Icons.radio,
              trailing: isPlaying
                  ? Icon(Icons.equalizer, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () => provider.playTrack(track),
            );
          },
        );
      },
    );
  }
}
