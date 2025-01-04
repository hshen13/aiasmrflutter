import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../models/audio.dart' as audio_model;
import '../models/playlist.dart';
import '../widgets/main_layout.dart';
import '../routes/route_constants.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final appState = ref.read(appStateProvider.notifier);
      await Future.wait([
        appState.fetchPlaylists(),
        appState.fetchRecentlyPlayed(),
        appState.fetchFavorites(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '音频库',
      child: Consumer(
        builder: (context, ref, child) {
          final appState = ref.watch(appStateProvider);

          if (appState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (appState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[900]!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[900]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => ref.read(appStateProvider.notifier).clearError(),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildSection(
                  title: '播放列表',
                  items: appState.playlists,
                  itemBuilder: (playlist) => _buildPlaylistItem(context, playlist),
                  emptyMessage: '暂无播放列表',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '最近播放',
                  items: appState.recentlyPlayed,
                  itemBuilder: (item) => _buildTrackItem(context, item.track),
                  emptyMessage: '暂无最近播放',
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '收藏',
                  items: appState.favorites,
  itemBuilder: (track) => _buildTrackItem(context, track as audio_model.Track),
                  emptyMessage: '暂无收藏',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection<T>({
    required String title,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Center(
            child: Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(items[index]),
          ),
      ],
    );
  }

  Widget _buildPlaylistItem(BuildContext context, Playlist playlist) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.playlistDetail,
          arguments: playlist,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.playlist_play,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${playlist.tracks.length} 个音频',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, audio_model.Track track) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.audioPlayer,
          arguments: track,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: track.fullCoverUrl != null
                  ? Image.network(
                      track.fullCoverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white54,
                            size: 32,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    track.artist,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
