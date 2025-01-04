import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio.dart';
import '../core/storage/storage_service.dart';

// Android emulator host machine address
const String _apiBaseUrl = 'http://10.0.2.2:8000/api/v1';

enum PlayerState {
  stopped,
  playing,
  paused,
  loading,
}

class PlayerStateNotifier extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Track? _currentTrack;
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isRepeatEnabled = false;
  bool _isShuffleEnabled = false;
  final Set<String> _favorites = {};
  List<Track> _queue = [];
  int _currentIndex = -1;

  final StorageService _storageService;

  PlayerStateNotifier(this._storageService) {
    _init();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoritesJson = await _storageService.getFavorites();
    if (favoritesJson != null) {
      _favorites.addAll(Set<String>.from(favoritesJson));
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    await _storageService.setFavorites(_favorites.toList());
  }

  void _init() {
    _player.playerStateStream.listen((state) {
      if (state.playing) {
        _state = PlayerState.playing;
      } else {
        switch (state.processingState) {
          case ProcessingState.idle:
            _state = PlayerState.stopped;
            next(); // Auto-play next track
            break;
          case ProcessingState.loading:
            _state = PlayerState.loading;
            break;
          case ProcessingState.buffering:
            _state = PlayerState.loading;
            break;
          case ProcessingState.ready:
            _state = PlayerState.paused;
            break;
          case ProcessingState.completed:
            _state = PlayerState.stopped;
            break;
        }
      }
      notifyListeners();
    });

    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  Track? get currentTrack => _currentTrack;
  PlayerState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _state == PlayerState.playing;
  bool get isRepeatEnabled => _isRepeatEnabled;
  bool get isShuffleEnabled => _isShuffleEnabled;
  Stream<Duration> get positionStream => _player.positionStream;
  
  bool isFavorite(Track? track) => track != null && _favorites.contains(track.id);

  Future<void> play(Track track, {List<Track>? playlist}) async {
    if (playlist != null) {
      _queue = List.from(playlist);
      _currentIndex = _queue.indexOf(track);
    } else if (_currentTrack?.id != track.id) {
      _queue = [track];
      _currentIndex = 0;
    }
    
    if (_currentTrack?.id != track.id) {
      _currentTrack = track;
      await _player.setUrl(track.fullAudioUrl);
    }
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  void playPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty || _currentIndex < 0) return;
    
    int nextIndex;
    if (_isShuffleEnabled) {
      nextIndex = _getRandomIndex();
    } else {
      nextIndex = _currentIndex + 1;
      if (nextIndex >= _queue.length) {
        if (_isRepeatEnabled) {
          nextIndex = 0;
        } else {
          return;
        }
      }
    }
    
    _currentIndex = nextIndex;
    await play(_queue[_currentIndex]);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    
    // If we're past 3 seconds, restart the current track
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    // Otherwise go to previous track
    if (_currentIndex > 0) {
      _currentIndex--;
      await play(_queue[_currentIndex]);
    } else if (_isRepeatEnabled) {
      _currentIndex = _queue.length - 1;
      await play(_queue[_currentIndex]);
    }
  }

  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  Future<void> toggleFavorite(Track track) async {
    if (_favorites.contains(track.id)) {
      _favorites.remove(track.id);
    } else {
      _favorites.add(track.id);
    }
    await _saveFavorites();
    notifyListeners();
  }

  int _getRandomIndex() {
    if (_queue.length <= 1) return 0;
    final random = List.generate(_queue.length, (i) => i)..remove(_currentIndex);
    return random[DateTime.now().millisecondsSinceEpoch % random.length];
  }

  Future<void> stop() async {
    await _player.stop();
    _currentTrack = null;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
