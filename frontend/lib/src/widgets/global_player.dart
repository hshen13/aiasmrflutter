import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/player_state.dart';
import '../routes/route_constants.dart';

class GlobalPlayer extends ConsumerWidget {
  const GlobalPlayer({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  double _getProgress(Duration position, Duration duration) {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);

    if (playerState.currentTrack == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.fullPlayer,
        );
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: _getProgress(playerState.position, playerState.duration),
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 2,
            ),
            Expanded(
              child: Row(
                children: [
                  if (playerState.currentTrack?.fullCoverUrl != null)
                    Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          playerState.currentTrack!.fullCoverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white24,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playerState.currentTrack?.title ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            playerState.currentTrack?.artist ?? '',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        color: Colors.white,
                        iconSize: 24,
                        onPressed: () {
                          final newPosition = playerState.position - const Duration(seconds: 10);
                          ref.read(playerStateProvider.notifier).seek(newPosition);
                        },
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          color: Colors.black,
                          iconSize: 24,
                          onPressed: () {
                            if (playerState.isPlaying) {
                              ref.read(playerStateProvider.notifier).pause();
                            } else {
                              ref.read(playerStateProvider.notifier).play();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        color: Colors.white,
                        iconSize: 24,
                        onPressed: () {
                          final newPosition = playerState.position + const Duration(seconds: 10);
                          ref.read(playerStateProvider.notifier).seek(newPosition);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
