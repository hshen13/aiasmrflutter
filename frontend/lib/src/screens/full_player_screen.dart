import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/player_state.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:palette_generator/palette_generator.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  Color? dominantColor;
  String? _lastTrackId;

  @override
  void initState() {
    super.initState();
    _loadDominantColor();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentTrackId = ref.read(playerStateProvider).currentTrack?.id;
    if (_lastTrackId != currentTrackId) {
      _lastTrackId = currentTrackId;
      _loadDominantColor();
    }
  }

  Future<void> _loadDominantColor() async {
    final currentTrack = ref.read(playerStateProvider).currentTrack;
    if (currentTrack != null) {
      try {
        setState(() {
          dominantColor = Colors.black;
        });
      } catch (e) {
        debugPrint('Error loading dominant color: $e');
        if (mounted) {
          setState(() {
            dominantColor = Colors.black;
          });
        }
      }
    }
  }

  void _seekRelative(Duration offset) {
    final playerState = ref.read(playerStateProvider);
    final track = playerState.currentTrack;
    if (track == null) return;

    final duration = Duration(milliseconds: (track.duration * 1000).round());
    final currentPosition = playerState.position;
    final newPosition = currentPosition + offset;

    // Ensure new position is within bounds
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(0, duration.inMilliseconds),
    );

    ref.read(playerStateProvider.notifier).seek(clampedPosition);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final track = playerState.currentTrack;
    final isPlaying = playerState.isPlaying;
    final position = playerState.position;
    final duration = track != null
        ? Duration(milliseconds: (track.duration * 1000).round())
        : Duration.zero;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Fullscreen GIF background
          Positioned.fill(
            child: Image.network(
              track?.fullGifUrl ?? 'assets/gif/kafka_night.gif',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/gif/kafka_night.gif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.low,
                );
              },
            ),
          ),
          // Semi-transparent overlay gradient for better readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar with close button and artist info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (track != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      backgroundImage: track.fullUserAvatar != null
                                          ? NetworkImage(track.fullUserAvatar!)
                                          : null,
                                      radius: 15,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      track.artist,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Track title
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              track?.title ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Progress bar and controls
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            ProgressBar(
                              progress: position,
                              total: duration,
                              bufferedBarColor: Colors.white38,
                              baseBarColor: Colors.white10,
                              thumbColor: Colors.white,
                              timeLabelTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              progressBarColor: Colors.white,
                              onSeek: (duration) {
                                ref.read(playerStateProvider.notifier).seek(duration);
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.repeat),
                                  color: playerState.isLooping ? Colors.green : Colors.white,
                                  iconSize: 24,
                                  onPressed: () {
                                    ref.read(playerStateProvider.notifier).toggleLoop();
                                  },
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () => _seekRelative(const Duration(seconds: -10)),
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      if (isPlaying) {
                                        ref.read(playerStateProvider.notifier).pause();
                                      } else {
                                        ref.read(playerStateProvider.notifier).play();
                                      }
                                    },
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () => _seekRelative(const Duration(seconds: 10)),
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Bottom Navigation Bar
              const BottomNavBar(currentIndex: 2),
            ],
          ),
        ],
      ),
    );
  }
}
