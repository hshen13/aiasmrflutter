import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../models/user.dart';
import '../models/character.dart';
import '../models/audio.dart';
import '../models/playlist.dart';

class AppState extends ChangeNotifier {
  final ApiClient _apiClient;
  String? _error;
  bool _isLoading = false;
  User? _user;
  List<Character> _characters = [];
  List<Playlist> _playlists = [];
  List<RecentlyPlayed> _recentlyPlayed = [];
  List<Track> _favorites = [];

  AppState({required ApiClient apiClient}) : _apiClient = apiClient;

  String? get error => _error;
  bool get isLoading => _isLoading;
  User? get user => _user;
  List<Character> get characters => _characters;
  List<Playlist> get playlists => _playlists;
  List<RecentlyPlayed> get recentlyPlayed => _recentlyPlayed;
  List<Track> get favorites => _favorites;

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiClient.register(username, password);
      _user = response.user;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String username, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiClient.login(username, password);
      _user = response.user;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiClient.logout();
      _user = null;
      _characters = [];
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Clear user session
  void clearSession() {
    _user = null;
    _characters = [];
    notifyListeners();
  }

  Future<void> fetchCharacters() async {
    _setLoading(true);
    _setError(null);
    try {
      _characters = await _apiClient.getCharacters();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createCharacter(CharacterCreate character) async {
    _setLoading(true);
    _setError(null);
    try {
      final newCharacter = await _apiClient.createCharacter(character);
      _characters.add(newCharacter);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPlaylists() async {
    _setLoading(true);
    _setError(null);
    try {
      _playlists = await _apiClient.getPlaylists();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPlaylistById(String id) async {
    _setLoading(true);
    _setError(null);
    try {
      final playlist = await _apiClient.getPlaylistById(id);
      if (playlist != null) {
        final index = _playlists.indexWhere((p) => p.id == id);
        if (index != -1) {
          _playlists[index] = playlist;
        } else {
          _playlists.add(playlist);
        }
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchRecentlyPlayed() async {
    _setLoading(true);
    _setError(null);
    try {
      _recentlyPlayed = await _apiClient.getRecentlyPlayed();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFavorites() async {
    _setLoading(true);
    _setError(null);
    try {
      _favorites = await _apiClient.getFavorites();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToFavorites(String trackId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiClient.addToFavorites(trackId);
      await fetchFavorites();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFromFavorites(String trackId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiClient.removeFromFavorites(trackId);
      await fetchFavorites();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToRecentlyPlayed(String trackId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiClient.addToRecentlyPlayed(trackId);
      await fetchRecentlyPlayed();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
