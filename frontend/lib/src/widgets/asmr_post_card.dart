import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio.dart';
import '../routes/route_constants.dart';
import '../core/providers/player_state.dart';
import 'dart:math' as math;

class WaveformPainter extends CustomPainter {
  final Color color;
  final double barWidth;
  final double spacing;
  final math.Random _random = math.Random(42); // Fixed seed for consistent pattern

  WaveformPainter({
    required this.color,
    required this.barWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barCount = (size.width / (barWidth + spacing)).floor();
    final startX = (size.width - (barCount * (barWidth + spacing) - spacing)) / 2;

    for (var i = 0; i < barCount; i++) {
      final x = startX + i * (barWidth + spacing);
      final normalizedHeight = _random.nextDouble() * 0.8 + 0.2; // Height between 20% and 100%
      final barHeight = size.height * normalizedHeight;
      final y = (size.height - barHeight) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => false;
}


class ASMRPostCard extends ConsumerStatefulWidget {
  final Track track;
  final VoidCallback? onTap;

  const ASMRPostCard({
    super.key,
    required this.track,
    this.onTap,
  });

  @override
  ConsumerState<ASMRPostCard> createState() => _ASMRPostCardState();
}

class _ASMRPostCardState extends ConsumerState<ASMRPostCard> {
  bool get _isCurrentTrack => ref.watch(playerStateProvider).currentTrack?.id == widget.track.id;
  bool get _isPlaying => ref.watch(playerStateProvider).isPlaying && _isCurrentTrack;
  Duration get _position => _isCurrentTrack ? ref.watch(playerStateProvider).position : Duration.zero;

  Future<void> _togglePlayPause() async {
    final playerNotifier = ref.read(playerStateProvider.notifier);
    if (_isCurrentTrack) {
      if (_isPlaying) {
        await playerNotifier.pause();
      } else {
        await playerNotifier.play();
      }
    } else {
      await playerNotifier.playTrack(widget.track);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.pushNamed(
        context,
        Routes.audioPlayer,
        arguments: widget.track,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: widget.track.fullCoverUrl != null
              ? Image.network(
                  widget.track.fullCoverUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and duration
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '立体声',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(Duration(seconds: widget.track.duration.round())),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Title and description
                Text(
                  widget.track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.track.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.track.description!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Audio player controls
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.purple[200],
                ),
                iconSize: 32,
                padding: EdgeInsets.zero,
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Waveform visualization using gradient
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CustomPaint(
                        painter: WaveformPainter(
                          color: Colors.grey[800]!,
                          barWidth: 2,
                          spacing: 3,
                        ),
                      ),
                    ),
                    // Progress indicator
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LinearProgressIndicator(
                          value: widget.track.duration > 0
                              ? _position.inSeconds / widget.track.duration
                              : 0,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[200]!),
                          minHeight: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
