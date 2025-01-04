import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/message.dart';
import '../core/storage/storage_service.dart';
import '../core/di/service_locator.dart';
import '../config/env_config.dart';

class AudioMessageBubble extends StatefulWidget {
  final Message message;
  final bool isUser;

  const AudioMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

      try {
        final mediaUrl = widget.message.mediaUrl;
        debugPrint('=== Audio Message Debug ===');
        debugPrint('Message ID: ${widget.message.id}');
        debugPrint('Message content: ${widget.message.content}');
        debugPrint('Message type: ${widget.message.type}');
        debugPrint('Is user message: ${widget.message.isUser}');
        debugPrint('Media URL: $mediaUrl');
        debugPrint('========================');
        if (mediaUrl.isEmpty) {
          debugPrint('Empty media URL, skipping audio initialization');
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          return;
        }

        debugPrint('Attempting to set audio URL: $mediaUrl');
        try {
          debugPrint('Raw media URL: $mediaUrl');
          if (mediaUrl.isEmpty) {
            debugPrint('Empty media URL, skipping audio initialization');
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
            return;
          }

          // Get auth token
          final storageService = getIt<StorageService>();
          final token = await storageService.getAccessToken();
          if (token == null) {
            debugPrint('No auth token available');
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
            return;
          }

          final uri = Uri.parse(mediaUrl);
          debugPrint('Parsed URI: $uri');

          final audioSource = AudioSource.uri(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'audio/mpeg',
            },
          );
          debugPrint('Created audio source with URI: $uri and token: ${token.substring(0, 10)}...');
          debugPrint('Created audio source');
          
          await _player.setAudioSource(audioSource);
        debugPrint('Successfully set audio source');
        
        final duration = await _player.duration;
        debugPrint('Audio duration: $duration');
        if (duration == null) {
          debugPrint('Failed to get audio duration');
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          return;
        }
        debugPrint('Successfully loaded audio');
        setState(() {
          _duration = duration;
          _isLoading = false;
        });

        _player.positionStream.listen(
          (position) {
            setState(() {
              _position = position;
            });
          },
          onError: (e) {
            debugPrint('Error in position stream: $e');
            setState(() {
              _hasError = true;
            });
          },
        );

        _player.playerStateStream.listen(
          (state) {
            setState(() {
              _isPlaying = state.playing;
            });
          },
          onError: (e) {
            debugPrint('Error in player state stream: $e');
            setState(() {
              _hasError = true;
            });
          },
        );

        // Listen for errors during playback
        _player.playbackEventStream.listen(
          (event) {},
          onError: (e) {
            debugPrint('Error in playback stream: $e');
            setState(() {
              _hasError = true;
            });
          },
        );
      } catch (e, stackTrace) {
        debugPrint('Error setting audio source: $e');
        debugPrint('Stack trace: $stackTrace');
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isUser
                  ? theme.colorScheme.primary
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.content,
                  style: TextStyle(
                    color: widget.isUser
                        ? Colors.white
                        : const Color(0xFFE0E0E0),
                    fontSize: 16,
                  ),
                ),
                if (widget.message.mediaUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.isUser ? Colors.white : const Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        )
                      else if (_hasError)
                        IconButton(
                          icon: Icon(
                            Icons.error_outline,
                            color: widget.isUser ? Colors.white : Colors.red,
                          ),
                          onPressed: _initAudio,
                          tooltip: 'Retry loading audio',
                        )
                      else
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isUser ? Colors.white : const Color(0xFF6C63FF),
                          ),
                          onPressed: () async {
                            try {
                              if (_isPlaying) {
                                await _player.pause();
                              } else {
                                await _player.play();
                              }
                            } catch (e) {
                              debugPrint('Error playing audio: $e');
                              setState(() {
                                _hasError = true;
                              });
                            }
                          },
                        ),
                      if (!_isLoading && !_hasError) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  trackHeight: 2,
                                  activeTrackColor: widget.isUser ? Colors.white : const Color(0xFF6C63FF),
                                  inactiveTrackColor: widget.isUser ? Colors.white.withOpacity(0.3) : const Color(0xFF4A4A4A),
                                  thumbColor: widget.isUser ? Colors.white : const Color(0xFF6C63FF),
                                ),
                                child: Slider(
                                  value: _position.inSeconds.toDouble(),
                                  max: _duration.inSeconds.toDouble(),
                                  onChanged: (value) async {
                                    try {
                                      final position = Duration(seconds: value.toInt());
                                      await _player.seek(position);
                                    } catch (e) {
                                      debugPrint('Error seeking audio: $e');
                                      setState(() {
                                        _hasError = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            Text(
                              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.isUser
                                    ? Colors.white.withOpacity(0.7)
                                    : const Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
