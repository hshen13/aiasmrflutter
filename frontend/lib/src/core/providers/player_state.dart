import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';

import '../../models/audio.dart';
import '../storage/storage_service.dart';
import '../di/service_locator.dart';
import '../network/dio_client.dart';

class PlayerState {
  final AudioPlayer player;
  final Track? currentTrack;
  final String? currentUrl;
  final bool isPlaying;
  final bool isLooping;
  final Duration position;
  final Duration duration;

  PlayerState._({
    required this.player,
    this.currentTrack,
    this.currentUrl,
    this.isPlaying = false,
    this.isLooping = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  factory PlayerState.initial(AudioPlayer player) {
    return PlayerState._(
      player: player,
      currentTrack: null,
      currentUrl: null,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  PlayerState copyWith({
    AudioPlayer? player,
    Track? currentTrack,
    String? currentUrl,
    bool? isPlaying,
    bool? isLooping,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerState._(
      player: player ?? this.player,
      currentTrack: currentTrack ?? this.currentTrack,
      currentUrl: currentUrl ?? this.currentUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      isLooping: isLooping ?? this.isLooping,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _player;
  final StorageService _storageService;

  static final AudioPlayer _sharedPlayer = AudioPlayer();

  PlayerStateNotifier({required StorageService storageService}) 
    : _player = _sharedPlayer, 
      _storageService = storageService,
      super(PlayerState.initial(_sharedPlayer)) {
    _initializeListeners();
  }

  late final StreamSubscription _playerStateSubscription;
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _durationSubscription;

  void _initializeListeners() {
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
      );
    });

    _positionSubscription = _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  Future<void> playTrack(Track track) async {
    if (track.id != state.currentTrack?.id) {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      final audioUrl = track.fullAudioUrl;
      await _player.setUrl(
        audioUrl,
        headers: {
          'Authorization': 'Bearer $token'
        }
      );
      
      // Wait for the duration to be loaded
      final duration = await _player.durationFuture;
      if (duration != null) {
        final actualDuration = duration.inMilliseconds / 1000.0;
        if ((actualDuration - track.duration).abs() > 0.5) { // Allow 0.5s difference
          try {
            // Update duration in backend
            final dioClient = getIt<DioClient>();
            final response = await dioClient.patch(
              '/api/v1/audio/tracks/${track.id}/duration',
              data: {'duration': actualDuration}
            );
            
            if (response.statusCode == 200) {
              // Update track with actual duration from response
              track = Track.fromJson(response.data);
            }
          } catch (e) {
            print('Failed to update track duration: $e');
            // Continue with local update even if API call fails
            track = Track(
              id: track.id,
              title: track.title,
              description: track.description,
              audio_url: track.audio_url,
              artist: track.artist,
              duration: actualDuration,
              cover_url: track.cover_url,
              userId: track.userId,
              username: track.username,
              userAvatar: track.userAvatar,
              createdAt: track.createdAt,
              updatedAt: track.updatedAt,
            );
          }
        }
      }

      await _player.setLoopMode(state.isLooping ? LoopMode.one : LoopMode.off);
      state = state.copyWith(
        currentTrack: track,
        currentUrl: audioUrl,
      );
    }
    await play();
  }

  Future<void> toggleLoop() async {
    final newLoopState = !state.isLooping;
    await _player.setLoopMode(newLoopState ? LoopMode.one : LoopMode.off);
    state = state.copyWith(isLooping: newLoopState);
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    super.dispose();
  }
}

final playerStateProvider =
    StateNotifierProvider.autoDispose<PlayerStateNotifier, PlayerState>((ref) {
      try {
        final storageService = getIt<StorageService>();
        return PlayerStateNotifier(storageService: storageService);
      } catch (e) {
        throw Exception('Failed to get StorageService: $e');
      }
    });
