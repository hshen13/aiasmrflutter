import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/auth_response.dart';
import '../../models/character.dart';
import '../../models/audio.dart';
import '../../models/playlist.dart';
import '../../models/message.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../storage/storage_service.dart';
import '../network/dio_client.dart';

class ApiClient {
  final DioClient _dioClient;

  ApiClient(this._dioClient);

  Future<AuthResponse> register(String username, String password) async {
    try {
      debugPrint('Attempting registration for user: $username');
      final response = await _dioClient.post(
        '/api/v1/auth/signup',
        data: {
          'username': username,
          'password': password,
        },
      );
      debugPrint('Registration successful');
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    }
  }

  Future<AuthResponse> login(String username, String password) async {
    try {
      debugPrint('Attempting login for user: $username');
      final response = await _dioClient.post(
        '/api/v1/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      debugPrint('Login successful');
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('Attempting logout');
      await _dioClient.post('/api/v1/auth/logout');
      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout failed: $e');
      rethrow;
    }
  }

  Future<List<Character>> getCharacters() async {
    try {
      debugPrint('Fetching characters');
      final response = await _dioClient.get('/api/v1/characters');
      final data = response.data as Map<String, dynamic>;
      debugPrint('Characters response data: $data');
      if (!data.containsKey('characters')) {
        debugPrint('Error: Response data does not contain "characters" key');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
      final characters = (data['characters'] as List)
          .map((json) {
            debugPrint('Processing character: $json');
            return Character.fromJson(json as Map<String, dynamic>);
          })
          .toList();
      debugPrint('Fetched ${characters.length} characters');
      return characters;
    } catch (e) {
      debugPrint('Failed to fetch characters: $e');
      rethrow;
    }
  }

  Future<Character> createCharacter(CharacterCreate character) async {
    try {
      debugPrint('Creating new character');
      final response = await _dioClient.post(
        '/api/v1/characters',
        data: character.toJson(),
      );
      debugPrint('Character created successfully');
      return Character.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to create character: $e');
      rethrow;
    }
  }

  Future<List<Playlist>> getPlaylists() async {
    try {
      debugPrint('Fetching playlists');
      final response = await _dioClient.get('/api/v1/audio/playlists');
      if (response.statusCode != 200) {
        debugPrint('Error getting playlists: Status code ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to get playlists',
        );
      }
      if (response.data == null) {
        debugPrint('Warning: Playlists response data is null');
        return [];
      }
      if (response.data is! List) {
        debugPrint('Error: Playlists response data is not a List. Got: ${response.data.runtimeType}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
      final playlists = response.data as List<dynamic>;
      final result = playlists
          .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('Fetched ${result.length} playlists');
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error getting playlists: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Playlist?> getPlaylistById(String id) async {
    try {
      debugPrint('Fetching playlist $id');
      final response = await _dioClient.get('/api/v1/audio/playlists/$id');
      if (response.statusCode != 200) {
        debugPrint('Error getting playlist $id: Status code ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to get playlist',
        );
      }
      if (response.data == null) {
        debugPrint('Warning: Playlist $id response data is null');
        return null;
      }
      final playlist = Playlist.fromJson(response.data as Map<String, dynamic>);
      debugPrint('Fetched playlist ${playlist.title} with ${playlist.tracks.length} tracks');
      return playlist;
    } catch (e, stackTrace) {
      debugPrint('Error getting playlist $id: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<RecentlyPlayed>> getRecentlyPlayed() async {
    try {
      debugPrint('Fetching recently played tracks');
      final response = await _dioClient.get('/api/v1/audio/recently-played');
      if (response.statusCode != 200) {
        debugPrint('Error getting recently played: Status code ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to get recently played',
        );
      }
      if (response.data == null) {
        debugPrint('Warning: Recently played response data is null');
        return [];
      }
      if (response.data is! List) {
        debugPrint('Error: Recently played response data is not a List. Got: ${response.data.runtimeType}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
      final items = response.data as List<dynamic>;
      final result = items
          .map((json) => RecentlyPlayed.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('Fetched ${result.length} recently played items');
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error getting recently played: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Track>> getFavorites() async {
    try {
      debugPrint('Fetching favorite tracks');
      final response = await _dioClient.get('/api/v1/audio/favorites');
      if (response.statusCode != 200) {
        debugPrint('Error getting favorites: Status code ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to get favorites',
        );
      }
      if (response.data == null) {
        debugPrint('Warning: Favorites response data is null');
        return [];
      }
      if (response.data is! List) {
        debugPrint('Error: Favorites response data is not a List. Got: ${response.data.runtimeType}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
      final tracks = response.data as List<dynamic>;
      final result = tracks
          .map((json) => Track.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('Fetched ${result.length} favorite tracks');
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error getting favorites: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> addToFavorites(String trackId) async {
    try {
      debugPrint('Adding track $trackId to favorites');
      await _dioClient.post('/api/v1/audio/favorites/$trackId');
      debugPrint('Successfully added track to favorites');
    } catch (e) {
      debugPrint('Failed to add track to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String trackId) async {
    try {
      debugPrint('Removing track $trackId from favorites');
      await _dioClient.delete('/api/v1/audio/favorites/$trackId');
      debugPrint('Successfully removed track from favorites');
    } catch (e) {
      debugPrint('Failed to remove track from favorites: $e');
      rethrow;
    }
  }

  Future<void> addToRecentlyPlayed(String trackId) async {
    try {
      debugPrint('Adding track $trackId to recently played');
      await _dioClient.post('/api/v1/audio/recently-played/$trackId');
      debugPrint('Successfully added track to recently played');
    } catch (e) {
      debugPrint('Failed to add track to recently played: $e');
      rethrow;
    }
  }

  Future<List<Track>> getTracks({int skip = 0, int limit = 100}) async {
    try {
      debugPrint('Fetching tracks');
      final response = await _dioClient.get('/api/v1/audio/tracks', queryParameters: {
        'skip': skip,
        'limit': limit,
      });
      if (response.statusCode != 200) {
        debugPrint('Error getting tracks: Status code ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to get tracks',
        );
      }
      if (response.data == null) {
        debugPrint('Warning: Tracks response data is null');
        return [];
      }
      if (response.data is! List) {
        debugPrint('Error: Tracks response data is not a List. Got: ${response.data.runtimeType}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
      final tracks = response.data as List<dynamic>;
      final result = tracks
          .map((json) => Track.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('Fetched ${result.length} tracks');
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error getting tracks: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Chat>> getChats() async {
    try {
      debugPrint('Fetching chats');
      final response = await _dioClient.get('/api/v1/chats');
      debugPrint('Chats response data: ${response.data}');
      if (response.data == null) {
        debugPrint('Warning: Chats response data is null');
        return [];
      }
      final data = response.data as Map<String, dynamic>;
      if (!data.containsKey('items')) {
        debugPrint('Error: Response data does not contain "items" key');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
      final chats = (data['items'] as List)
          .map((json) {
            debugPrint('Processing chat: $json');
            return Chat.fromJson(json as Map<String, dynamic>);
          })
          .toList();
      debugPrint('Fetched ${chats.length} chats');
      return chats;
    } catch (e) {
      debugPrint('Failed to fetch chats: $e');
      rethrow;
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      debugPrint('Fetching messages for chat $chatId');
      final response = await _dioClient.get('/api/v1/chats/$chatId/messages');
      debugPrint('Messages response data: ${response.data}');
      if (response.data == null) {
        debugPrint('Warning: Messages response data is null');
        return [];
      }
      final data = response.data as Map<String, dynamic>;
      if (!data.containsKey('messages')) {
        debugPrint('Error: Response data does not contain "messages" key');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
      final messages = (data['messages'] as List)
          .map((json) {
            debugPrint('Processing message: $json');
            return Message.fromJson(json as Map<String, dynamic>);
          })
          .toList();
      debugPrint('Fetched ${messages.length} messages');
      return messages;
    } catch (e) {
      debugPrint('Failed to fetch chat messages: $e');
      rethrow;
    }
  }

  Future<MessageResponse> sendMessage(String chatId, String content) async {
    try {
      debugPrint('Sending message to chat $chatId');
      final response = await _dioClient.post(
        '/api/v1/chats/$chatId/messages',
        data: {'content': content, 'type': 'text'},
      );
      debugPrint('Message response data: ${response.data}');
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Empty response data',
        );
      }
      final messageResponse = MessageResponse.fromJson(response.data as Map<String, dynamic>);
      debugPrint('Message sent successfully with ${messageResponse.messages.length} messages');
      return messageResponse;
    } catch (e) {
      debugPrint('Failed to send message: $e');
      rethrow;
    }
  }

  Future<User> getProfile() async {
    try {
      debugPrint('Fetching user profile');
      final response = await _dioClient.get('/api/v1/auth/profile');
      debugPrint('Profile response data: ${response.data}');
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Empty response data',
        );
      }
      final user = User.fromJson(response.data as Map<String, dynamic>);
      debugPrint('Successfully fetched user profile');
      return user;
    } catch (e) {
      debugPrint('Failed to fetch user profile: $e');
      rethrow;
    }
  }

  Future<Chat> createChat(String characterId) async {
    try {
      debugPrint('Creating new chat with character $characterId');
      final response = await _dioClient.post(
        '/api/v1/chats',
        data: {
          'character_id': characterId,
          'title': null,  // Let backend use character name as default
          'description': null  // Let backend use character description as default
        },
      );
      debugPrint('Chat response data: ${response.data}');
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Empty response data',
        );
      }
      final chat = Chat.fromJson(response.data as Map<String, dynamic>);
      debugPrint('Chat created successfully with id: ${chat.id}');
      return chat;
    } catch (e) {
      debugPrint('Failed to create chat: $e');
      rethrow;
    }
  }
}
