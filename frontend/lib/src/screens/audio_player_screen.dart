import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/player_state.dart';
import '../models/audio.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final Track track;

  const AudioPlayerScreen({
    Key? key,
    required this.track,
  }) : super(key: key);

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (ref.read(playerStateProvider).currentTrack?.id != widget.track.id) {
        await ref.read(playerStateProvider.notifier).playTrack(widget.track);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final isCurrentTrack = playerState.currentTrack?.id == widget.track.id;
    final isPlaying = playerState.isPlaying && isCurrentTrack;
    final position = isCurrentTrack ? playerState.position : Duration.zero;
    final duration = isCurrentTrack ? playerState.duration : Duration(seconds: widget.track.duration.round());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            // Album art
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.track.fullCoverUrl != null
                          ? Image.network(
                              widget.track.fullCoverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Icon(
                                    Icons.music_note,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.music_note,
                                size: 64,
                                color: Colors.white24,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            // Track info and controls
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Title and artist
                    Column(
                      children: [
                        Text(
                          widget.track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.track.artist,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    // Progress bar
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            activeTrackColor: Colors.green,
                            inactiveTrackColor: Colors.grey[800],
                            thumbColor: Colors.white,
                            overlayColor: Colors.green.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: position.inSeconds.toDouble(),
                            min: 0,
                            max: duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              ref.read(playerStateProvider.notifier).seek(
                                    Duration(seconds: value.toInt()),
                                  );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.repeat),
                              color: playerState.isLooping ? Colors.green : Colors.white,
                              iconSize: 24,
                              onPressed: () {
                                ref.read(playerStateProvider.notifier).toggleLoop();
                              },
                            ),
                            Text(
                              playerState.isLooping ? '循环开启' : '循环关闭',
                              style: TextStyle(
                                color: playerState.isLooping ? Colors.green : Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () {
                            final newPosition = position - const Duration(seconds: 10);
                            ref.read(playerStateProvider.notifier).seek(
                                  Duration(seconds: newPosition.inSeconds.clamp(0, duration.inSeconds)),
                                );
                          },
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            color: Colors.black,
                            iconSize: 32,
                            onPressed: () {
                              if (isPlaying) {
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
                          iconSize: 32,
                          onPressed: () {
                            final newPosition = position + const Duration(seconds: 10);
                            ref.read(playerStateProvider.notifier).seek(
                                  Duration(seconds: newPosition.inSeconds.clamp(0, duration.inSeconds)),
                                );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
