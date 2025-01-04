import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../core/providers/player_state.dart';
import '../models/playlist.dart';
import '../models/audio.dart';
import '../widgets/main_layout.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return MainLayout(
      title: widget.playlist.title,
      child: Stack(
        children: [
          if (appState.isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.playlist.tracks.length,
              itemBuilder: (context, index) {
                final track = widget.playlist.tracks[index];
                return _buildTrackItem(context, track);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, Track track) {
    return Container(
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
          IconButton(
            icon: const Icon(Icons.play_arrow),
            color: Colors.white,
            onPressed: () {
              ref.read(playerStateProvider.notifier).playTrack(track);
            },
          ),
        ],
      ),
    );
  }
}
