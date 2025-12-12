import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/background_music_provider.dart';
import '../../../widgets/glass/glass_container.dart';
import '../../../i18n/i18n.dart';

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
    
    return GlassContainer(
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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final provider = context.read<BackgroundMusicProvider>();
                  provider.fetchDefaultTracks();
                  provider.fetchRadioTracks();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).hintColor,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: i18n?.localTab ?? 'Local'),
              Tab(text: i18n?.defaultTab ?? 'Default'),
              Tab(text: i18n?.radioTab ?? 'Radio'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLocalList(context),
                _buildDefaultList(context),
                _buildRadioList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalList(BuildContext context) {
    final i18n = APPi18n.of(context);
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.playlist;
        if (tracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(i18n?.noLocalMusicImported ?? 'No local music imported'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.importMusic(),
                  icon: const Icon(Icons.add),
                  label: Text(i18n?.importFromDevice ?? 'Import from Device'),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => provider.importMusic(),
                icon: const Icon(Icons.add),
                label: Text(i18n?.addMore ?? 'Add More'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isPlaying = provider.currentTrack?.id == track.id;
                  return ListTile(
                    title: Text(track.title),
                    subtitle: Text(track.artist),
                    leading: Icon(
                      isPlaying ? Icons.music_note : Icons.music_off,
                      color: isPlaying ? Theme.of(context).primaryColor : null,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => provider.removeTrack(track),
                    ),
                    onTap: () => provider.playTrack(track),
                    selected: isPlaying,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultList(BuildContext context) {
    final i18n = APPi18n.of(context);
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.defaultTracks;
        if (provider.isLoadingMusic) {
          return const Center(child: CircularProgressIndicator());
        }
        if (tracks.isEmpty) {
          return Center(
            child: Text(i18n?.noDefaultTracks ?? 'No default tracks available'),
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isDownloaded = track.isLocal || track.localPath != null;
            final isPlaying = provider.currentTrack?.id == track.id;

            return ListTile(
              title: Text(track.title),
              subtitle: Text(track.artist),
              leading: Icon(
                isPlaying ? Icons.play_circle_filled : Icons.music_note,
                color: isPlaying ? Theme.of(context).primaryColor : null,
              ),
              trailing: isDownloaded
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => provider.removeTrack(track),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => provider.downloadTrack(track),
                    ),
              onTap: () {
                if (isDownloaded) {
                  provider.playTrack(track);
                } else {
                  // Maybe prompt to download first? Or stream?
                  // For now, let's stream it
                  provider.playTrack(track);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRadioList(BuildContext context) {
    final i18n = APPi18n.of(context);
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.radioTracks;
        if (tracks.isEmpty) {
          return Center(
            child: Text(
              i18n?.noRadioStationsAvailable ?? 'No radio stations available',
            ),
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final isPlaying = provider.currentTrack?.id == track.id;
            return ListTile(
              title: Text(track.title),
              subtitle: Text(track.artist),
              leading: const Icon(Icons.radio),
              trailing: isPlaying ? const Icon(Icons.equalizer) : null,
              onTap: () => provider.playTrack(track),
              selected: isPlaying,
            );
          },
        );
      },
    );
  }
}
