import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_state.dart';
import '../routes/route_constants.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _completer = Completer<void>();
  StreamSubscription? _eventSubscription;
  StreamSubscription? _processingStateSubscription;
  bool _isDisposed = false;

  AudioPlayerHandler() {
    _eventSubscription = _player.playbackEventStream.listen(_broadcastState);
    _processingStateSubscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    if (_isDisposed) return;
    try {
      final headers = extras?['headers'] as Map<String, String>?;
      final metadata = extras?['metadata'] as MediaItem?;
      
      await _player.setAudioSource(
        AudioSource.uri(uri, headers: headers),
      );
      if (metadata != null) {
        mediaItem.add(metadata);
      }
      await play();
    } catch (e) {
      debugPrint('Error playing from URI: $e');
      if (!_completer.isCompleted) {
        _completer.completeError(e);
      }
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    if (_isDisposed) return;
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) return;
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) return;
    try {
      await _player.stop();
      await _cleanup();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
      rethrow;
    }
  }

  Future<void> _cleanup() async {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      await _eventSubscription?.cancel();
      await _processingStateSubscription?.cancel();
      await _player.dispose();
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
      if (!_completer.isCompleted) {
        _completer.completeError(e);
      }
    }
  }

  void _broadcastState(PlaybackEvent event) {
    if (_isDisposed) return;
    try {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    } catch (e) {
      debugPrint('Error broadcasting state: $e');
    }
  }
}

class AIChatScreen extends ConsumerStatefulWidget {
  final String characterId;

  const AIChatScreen({super.key, required this.characterId});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Chat? _currentChat;
  bool _isSendingMessage = false;
  String? _currentlyPlayingMessageId;
  bool _isLoading = true;
  AudioHandler? _audioHandler;
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _customEventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    try {
      final appState = ref.read(appStateProvider);
      if (!appState.isAuthenticated) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.login);
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Create chat with character
      debugPrint('Creating new chat with character: ${widget.characterId}');
      final chat = await ref.read(appStateProvider.notifier).createChat(widget.characterId);
      if (chat != null) {
        setState(() {
          _currentChat = chat;
          _isLoading = false;
        });
        debugPrint('Chat created successfully: ${chat.id}');
        _scrollToBottom();
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      debugPrint('Error in chat initialization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize chat: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioHandler?.stop();
    _playbackStateSubscription?.cancel();
    _customEventSubscription?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _playAudio(String messageId, String audioUrl) async {
    debugPrint('Attempting to play audio - Message ID: $messageId, URL: $audioUrl');
    
    if (_currentlyPlayingMessageId == messageId) {
      debugPrint('Stopping current audio playback');
      await _audioHandler?.stop();
      setState(() {
        _currentlyPlayingMessageId = null;
      });
      return;
    }

    setState(() {
      _currentlyPlayingMessageId = messageId;
    });

    try {
      // Ensure we have a valid URL
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        audioUrl = 'http://10.0.2.2:8000$audioUrl';
      }
      debugPrint('Setting audio URL: $audioUrl');

      // Configure audio session first
      debugPrint('Configuring audio session...');
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
      ));
      debugPrint('Audio session configured');

      // Get access token
      final token = await ref.read(appStateProvider.notifier).getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      // Initialize audio service if not already initialized
      if (_audioHandler == null) {
        debugPrint('Initializing audio service...');
        _audioHandler = await AudioService.init(
          builder: () => AudioPlayerHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.aiasmr.audio',
            androidNotificationChannelName: 'AIASMR Audio',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
          ),
        );
      }

      try {
        // Play audio through audio service
        debugPrint('Starting audio playback...');
        await _audioHandler?.playFromUri(
          Uri.parse(audioUrl),
          {
            'headers': {
              'Accept': 'audio/mpeg',
              'Origin': 'http://10.0.2.2:8000',
              'Range': 'bytes=0-',  // Add range header for streaming support
              'Cache-Control': 'no-cache',  // Prevent caching issues
              'Authorization': 'Bearer $token',
            },
            'metadata': MediaItem(
              id: messageId,
              title: 'ASMR Audio',
              artist: _currentChat?.characterName ?? 'AI',
            ),
          },
        );
        debugPrint('Audio playback started');
      } catch (e) {
        await _audioHandler?.stop();
        rethrow;
      }
      
      // Listen for playback state changes
      _playbackStateSubscription?.cancel();
      _playbackStateSubscription = AudioService.playbackStateStream.listen((state) {
        debugPrint('Audio service state changed: ${state.processingState}');
        if (state.processingState == AudioProcessingState.completed) {
          debugPrint('Audio playback completed');
          if (mounted) {
            setState(() {
              _currentlyPlayingMessageId = null;
            });
          }
        }
      });

      // Listen for errors
      _customEventSubscription?.cancel();
      _customEventSubscription = AudioService.customEventStream.listen((event) {
        if (event is String && event.startsWith('error:')) {
          debugPrint('Audio service error: $event');
          if (mounted) {
            setState(() {
              _currentlyPlayingMessageId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Audio playback error: ${event.substring(6)}')),
            );
          }
        }
      });

    } catch (e, stackTrace) {
      debugPrint('Error playing audio: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: ${e.toString()}')),
        );
        setState(() {
          _currentlyPlayingMessageId = null;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_currentChat == null) return;
    
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      _messageController.clear();
      await ref.read(appStateProvider.notifier).sendMessage(_currentChat!.id, message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentChat?.characterName ?? 'AI Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading || _currentChat == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: appState.chatMessages[_currentChat!.id]?.length ?? 0,
                        itemBuilder: (context, index) {
                          final messages = appState.chatMessages[_currentChat!.id] ?? [];
                          final message = messages[index];
                          return _MessageBubble(
                            message: message,
                            showAvatar: !message.isUser,
                            avatarUrl: _currentChat?.characterAvatar,
                            isPlaying: _currentlyPlayingMessageId == message.id,
                            onPlayAudio: message.mediaUrl.isNotEmpty
                                ? () => _playAudio(message.id, message.mediaUrl)
                                : null,
                          );
                        },
                      ),
                      if (appState.isLoading)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isSendingMessage)
                  const LinearProgressIndicator(),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isSendingMessage,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSendingMessage ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final String? avatarUrl;
  final bool isPlaying;
  final VoidCallback? onPlayAudio;

  const _MessageBubble({
    required this.message,
    this.showAvatar = false,
    this.avatarUrl,
    this.isPlaying = false,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showAvatar) ...[
            CircleAvatar(
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[700] : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (!isUser && onPlayAudio != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onPlayAudio,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPlaying ? 'Stop' : 'Play',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
