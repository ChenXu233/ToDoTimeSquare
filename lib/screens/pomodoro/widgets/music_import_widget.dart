import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/background_music_provider.dart';
import '../../../widgets/glass/glass_container.dart';

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
                'Music Library',
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
            tabs: const [
              Tab(text: 'Local'),
              Tab(text: 'Default'),
              Tab(text: 'Radio'),
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
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.playlist;
        if (tracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No local music imported'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.importMusic(),
                  icon: const Icon(Icons.add),
                  label: const Text('Import from Device'),
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
                label: const Text('Add More'),
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
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.defaultTracks;
        if (provider.isLoadingMusic) {
          return const Center(child: CircularProgressIndicator());
        }
        if (tracks.isEmpty) {
          return const Center(child: Text('No default tracks available'));
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
    return Consumer<BackgroundMusicProvider>(
      builder: (context, provider, child) {
        final tracks = provider.radioTracks;
        if (tracks.isEmpty) {
          return const Center(child: Text('No radio stations available'));
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
