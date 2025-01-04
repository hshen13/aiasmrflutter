import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../models/audio.dart';
import '../models/playlist.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  // Auth endpoints
  Future<AuthResponse> login(String username, String password) async {
    final response = await _dioClient.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(String username, String password) async {
    final response = await _dioClient.post('/auth/register', data: {
      'username': username,
      'password': password,
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<User> getCurrentUser() async {
    final response = await _dioClient.get('/auth/me');
    return User.fromJson(response.data);
  }

  // Audio endpoints
  Future<List<Track>> getTracks({int skip = 0, int limit = 100}) async {
    final response = await _dioClient.get('/audio/tracks', queryParameters: {
      'skip': skip,
      'limit': limit,
    });
    return (response.data as List).map((json) => Track.fromJson(json)).toList();
  }

  Future<Track> getTrack(String trackId) async {
    final response = await _dioClient.get('/audio/tracks/$trackId');
    return Track.fromJson(response.data);
  }

  Future<List<Playlist>> getPlaylists() async {
    final response = await _dioClient.get('/audio/playlists');
    return (response.data as List).map((json) => Playlist.fromJson(json)).toList();
  }

  Future<Playlist> getPlaylist(String playlistId) async {
    final response = await _dioClient.get('/audio/playlists/$playlistId');
    return Playlist.fromJson(response.data);
  }

  Future<Playlist> createPlaylist(PlaylistCreate playlist) async {
    final response = await _dioClient.post('/audio/playlists', data: playlist.toJson());
    return Playlist.fromJson(response.data);
  }

  Future<Playlist> updatePlaylist(String playlistId, PlaylistUpdate playlist) async {
    final response = await _dioClient.put(
      '/audio/playlists/$playlistId',
      data: playlist.toJson(),
    );
    return Playlist.fromJson(response.data);
  }

  Future<Playlist> addTrackToPlaylist(String playlistId, String trackId) async {
    final response = await _dioClient.post(
      '/audio/playlists/$playlistId/tracks',
      data: {'track_id': trackId},
    );
    return Playlist.fromJson(response.data);
  }

  Future<Playlist> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final response = await _dioClient.delete(
      '/audio/playlists/$playlistId/tracks/$trackId',
    );
    return Playlist.fromJson(response.data);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _dioClient.delete('/audio/playlists/$playlistId');
  }

  Future<List<RecentlyPlayed>> getRecentlyPlayed({int limit = 20}) async {
    final response = await _dioClient.get('/audio/recently-played', queryParameters: {
      'limit': limit,
    });
    return (response.data as List).map((json) => RecentlyPlayed.fromJson(json)).toList();
  }

  Future<RecentlyPlayed> playTrack(String trackId) async {
    final response = await _dioClient.post('/audio/tracks/play/$trackId');
    return RecentlyPlayed.fromJson(response.data);
  }
}
