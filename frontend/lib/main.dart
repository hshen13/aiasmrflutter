import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/core/di/service_locator.dart';

class AudioSessionManager extends WidgetsBindingObserver {
  StreamSubscription? interruptionSubscription;
  StreamSubscription? becomingNoisySubscription;
  bool _isDisposed = false;

  Future<void> initialize() async {
    if (_isDisposed) {
      throw StateError('AudioSessionManager is already disposed');
    }

    try {
      final session = await AudioSession.instance;
      debugPrint('Audio session instance obtained');

      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      
      // Listen for audio interruptions
      interruptionSubscription = session.interruptionEventStream.listen((event) {
        debugPrint('Audio interruption: ${event.begin ? 'began' : 'ended'}');
        if (event.begin) {
          // Audio was interrupted, pause playback
          AudioService.pause();
        } else if (!event.begin && event.type == AudioInterruptionType.pause) {
          // Interruption ended, resume if we were playing
          AudioService.play();
        }
      }, onError: (e) {
        debugPrint('Error in interruption stream: $e');
      });

      // Listen for audio becomingNoisy events (e.g. headphones unplugged)
      becomingNoisySubscription = session.becomingNoisyEventStream.listen((_) {
        debugPrint('Audio becoming noisy, pausing playback');
        AudioService.pause();
      }, onError: (e) {
        debugPrint('Error in becomingNoisy stream: $e');
      });

      debugPrint('Audio session configured successfully');
    } catch (e, stack) {
      debugPrint('Failed to configure audio session: $e');
      debugPrint('Stack trace: $stack');
      await cleanup();
      // Rethrow to allow proper error handling upstream
      rethrow;
    }
  }

  Future<void> cleanup() async {
    if (_isDisposed) {
      debugPrint('AudioSessionManager is already disposed, skipping cleanup');
      return;
    }
    _isDisposed = true;
    
    debugPrint('Starting audio session cleanup');
    try {
      if (interruptionSubscription != null) {
        debugPrint('Canceling interruption subscription');
        await interruptionSubscription!.cancel();
        interruptionSubscription = null;
      }
      
      if (becomingNoisySubscription != null) {
        debugPrint('Canceling becomingNoisy subscription');
        await becomingNoisySubscription!.cancel();
        becomingNoisySubscription = null;
      }
      
      debugPrint('Audio session cleanup completed successfully');
    } catch (e, stack) {
      debugPrint('Error during audio session cleanup: $e');
      debugPrint('Stack trace: $stack');
      // Reset state even if cleanup fails
      interruptionSubscription = null;
      becomingNoisySubscription = null;
      // Don't rethrow as we want to ensure cleanup completes
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      debugPrint('App detached, initiating audio session cleanup');
      scheduleMicrotask(() async {
        try {
          await cleanup();
        } catch (e) {
          debugPrint('Error during lifecycle cleanup: $e');
        }
      });
    }
  }

  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() async => false;

  @override
  Future<bool> didPushRoute(String route) async => false;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async => false;
}

class LifecycleAwareHandler extends WidgetsBindingObserver {
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onDetach;

  LifecycleAwareHandler({
    required this.onPause,
    required this.onResume,
    required this.onDetach,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle lifecycle changes synchronously to avoid state inconsistencies
    switch (state) {
      case AppLifecycleState.paused:
        scheduleMicrotask(() async {
          try {
            await onPause();
          } catch (e) {
            debugPrint('Error during pause: $e');
          }
        });
        break;
      case AppLifecycleState.resumed:
        scheduleMicrotask(() async {
          try {
            await onResume();
          } catch (e) {
            debugPrint('Error during resume: $e');
          }
        });
        break;
      case AppLifecycleState.detached:
        scheduleMicrotask(() async {
          try {
            await onDetach();
          } catch (e) {
            debugPrint('Error during detach: $e');
          }
        });
        break;
      default:
        break;
    }
  }

  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() async => false;

  @override
  Future<bool> didPushRoute(String route) async => false;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async => false;
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final List<StreamSubscription> _subscriptions = [];
  bool _wasPlayingBeforeInterruption = false;

  AudioPlayerHandler() {
    _init();
    _setupLifecycleHandling();
  }

  void _setupLifecycleHandling() {
    final lifecycleHandler = LifecycleAwareHandler(
      onPause: () async {
        debugPrint('App paused, handling audio state');
        _wasPlayingBeforeInterruption = _player.playing;
        if (_wasPlayingBeforeInterruption) {
          await pause();
          debugPrint('Paused playback due to app pause');
        }
      },
      onResume: () async {
        debugPrint('App resumed, handling audio state');
        if (_wasPlayingBeforeInterruption) {
          await play();
          debugPrint('Resumed playback after app resume');
        }
      },
      onDetach: () async {
        debugPrint('App detached, cleaning up audio resources');
        await stop();
        await dispose();
        debugPrint('Audio resources cleaned up');
      },
    );
    WidgetsBinding.instance.addObserver(lifecycleHandler);
    // Store the handler to remove it later
    _lifecycleHandler = lifecycleHandler;
  }

  void _listenToPlaybackState() {
    final subscription = _player.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        stop();
      }
      if (event.currentIndex == null) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: 'No track loaded',
        ));
      }
    });
    _subscriptions.add(subscription);
  }

  void _listenToSequenceState() {
    final subscription = _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      final sequence = sequenceState.sequence;
      final items = sequence.map((source) => source.tag as MediaItem).toList();
      queue.add(items);
      
      // Update media item when current item changes
      if (sequence.isNotEmpty) {
        final currentItem = sequenceState.currentSource?.tag as MediaItem?;
        mediaItem.add(currentItem);
      }
    });
    _subscriptions.add(subscription);
  }

  void _listenToPlayerState() {
    final subscription = _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
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
        errorMessage: event.currentIndex == null && !playing
            ? 'No track selected'
            : _player.playerState.processingState == ProcessingState.completed
                ? 'Completed'
                : event.processingState == ProcessingState.idle && !playing
                    ? 'Stopped'
                    : null,
      ));
    });
    _subscriptions.add(subscription);
  }

  Future<void> _init() async {
    try {
      // Set initial state to loading
      playbackState.add(PlaybackState(
        controls: [],
        systemActions: const {},
        androidCompactActionIndices: const [],
        processingState: AudioProcessingState.loading,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ));

      // Initialize state
      mediaItem.add(null);
      queue.add([]);

      // Set up stream listeners before initializing audio source
      _listenToPlaybackState();
      _listenToSequenceState();
      _listenToPlayerState();

      // Initialize audio source
      await _player.setAudioSource(_playlist);

      // Update state to idle with controls
      playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ));

      debugPrint('Audio player initialized successfully');
    } catch (e) {
      debugPrint('Error initializing player: $e');
      // Update state to error
      playbackState.add(PlaybackState(
        controls: [],
        systemActions: const {},
        androidCompactActionIndices: const [],
        processingState: AudioProcessingState.error,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
        errorMessage: 'Error initializing player: $e',
      ));
      // Clean up subscriptions if initialization fails
      await dispose();
      rethrow;
    }
  }

  LifecycleAwareHandler? _lifecycleHandler;

  Future<void> dispose() async {
    debugPrint('Disposing AudioPlayerHandler');
    // Remove lifecycle observer
    if (_lifecycleHandler != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleHandler!);
      _lifecycleHandler = null;
    }
    // Cancel all stream subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _player.dispose();
    debugPrint('AudioPlayerHandler disposed successfully');
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Error playing: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to start playback',
      ));
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to pause playback',
      ));
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      await playbackState.firstWhere(
          (state) => state.processingState == AudioProcessingState.idle);
      mediaItem.add(null);
    } catch (e) {
      debugPrint('Error stopping: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to stop playback',
      ));
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to seek to position',
      ));
      rethrow;
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    try {
      if (name == 'dispose') {
        await stop();
        await dispose();
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
        ));
      }
      await super.customAction(name, extras);
    } catch (e) {
      debugPrint('Error in customAction: $e');
      rethrow;
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(mediaItem.id),
        tag: mediaItem,
      );
      await _playlist.add(audioSource);
    } catch (e) {
      debugPrint('Error adding queue item: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to add track: ${mediaItem.title}',
      ));
      rethrow;
    }
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    try {
      final index = queue.value.indexOf(mediaItem);
      if (index != -1) {
        await _playlist.removeAt(index);
      }
    } catch (e) {
      debugPrint('Error removing queue item: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to remove track: ${mediaItem.title}',
      ));
      rethrow;
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      await _player.seekToNext();
    } catch (e) {
      debugPrint('Error skipping to next: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to skip to next track',
      ));
      rethrow;
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      await _player.seekToPrevious();
    } catch (e) {
      debugPrint('Error skipping to previous: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to skip to previous track',
      ));
      rethrow;
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } catch (e) {
      debugPrint('Error setting speed: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: 'Failed to change playback speed',
      ));
      rethrow;
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    try {
      await stop();
      await dispose();
      mediaItem.add(null);
      queue.add([]);
    } catch (e) {
      debugPrint('Error cleaning up player: $e');
    }
  }
}

Future<void> initializeAudio() async {
  try {
    // Initialize audio session
    final audioSessionManager = AudioSessionManager();
    WidgetsBinding.instance.addObserver(audioSessionManager);
    await audioSessionManager.initialize();
    debugPrint('Audio session manager initialized successfully');

    // Initialize audio service
    await AudioService.init<AudioPlayerHandler>(
      builder: () {
        try {
          debugPrint('Creating audio handler...');
          final handler = AudioPlayerHandler();
          debugPrint('Audio handler created successfully');
          return handler;
        } catch (e, stack) {
          debugPrint('Failed to create audio handler: $e');
          debugPrint('Stack trace: $stack');
          // If handler creation fails, clean up audio session
          WidgetsBinding.instance.removeObserver(audioSessionManager);
          scheduleMicrotask(() async {
            try {
              await audioSessionManager.cleanup();
              debugPrint('Audio session cleaned up after handler creation failure');
            } catch (cleanupError) {
              debugPrint('Error during audio session cleanup: $cleanupError');
            }
          });
          rethrow;
        }
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.frontend.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );
    debugPrint('Audio service initialized successfully');
  } catch (e, stack) {
    debugPrint('Error initializing audio components: $e');
    debugPrint('Stack trace: $stack');
    debugPrint('Continuing with limited audio functionality');
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter binding initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Flutter binding: $e');
    rethrow;
  }

  try {
    await setupServiceLocator();
    debugPrint('Service locator initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize service locator: $e');
    rethrow;
  }

  // Initialize audio components before running the app
  await initializeAudio();

  // Run the app in a guarded zone
  runZonedGuarded(() {
    runApp(const ProviderScope(child: App()));
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}
