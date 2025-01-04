import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../storage/storage_service.dart';
import '../di/service_locator.dart';
import '../../models/user.dart';
import '../../models/character.dart';
import '../../models/audio.dart';
import '../../models/playlist.dart';
import '../../models/message.dart';
import '../../models/chat.dart';
import 'package:dio/dio.dart';

class AppStateData {
  final String? error;
  final bool isLoading;
  final bool isInitialized;
  final User? user;
  final List<Character> characters;
  final List<Playlist> playlists;
  final List<RecentlyPlayed> recentlyPlayed;
  final List<Track> favorites;
  final List<Track> tracks;
  final List<Chat> chats;
  final Map<String, List<Message>> chatMessages;

  AppStateData({
    this.error,
    this.isLoading = false,
    this.isInitialized = false,
    this.user,
    this.characters = const [],
    this.playlists = const [],
    this.recentlyPlayed = const [],
    this.favorites = const [],
    this.tracks = const [],
    this.chats = const [],
    this.chatMessages = const {},
  });

  bool get isAuthenticated => user != null;
  User? get currentUser => user;

  AppStateData copyWith({
    String? error,
    bool? isLoading,
    bool? isInitialized,
    User? user,
    List<Character>? characters,
    List<Playlist>? playlists,
    List<RecentlyPlayed>? recentlyPlayed,
    List<Track>? favorites,
    List<Track>? tracks,
    List<Chat>? chats,
    Map<String, List<Message>>? chatMessages,
  }) {
    return AppStateData(
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      user: user ?? this.user,
      characters: characters ?? this.characters,
      playlists: playlists ?? this.playlists,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      favorites: favorites ?? this.favorites,
      tracks: tracks ?? this.tracks,
      chats: chats ?? this.chats,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppStateData> {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AppStateNotifier({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService,
        super(AppStateData()) {
    _initialize();
  }

  void _setError(String? error) {
    state = state.copyWith(error: error);
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> logout() async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      await _apiClient.logout();
      await _storageService.clearTokens();  // Clear tokens from storage
      state = AppStateData();  // Reset app state
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Even if the API call fails, clear tokens and reset state
      await _storageService.clearTokens();
      state = AppStateData();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getAccessToken() async {
    return _storageService.getAccessToken();
  }

  Future<void> register(String username, String password) async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiClient.register(username, password);
      await _storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      state = state.copyWith(user: response.user);
      // Load initial data
      await Future.wait([
        loadCharacters(),
        fetchPlaylists(),
        fetchRecentlyPlayed(),
        fetchFavorites(),
      ]);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String username, String password) async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiClient.login(username, password);
      await _storageService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      state = state.copyWith(user: response.user);
      // Load initial data
      await Future.wait([
        loadCharacters(),
        fetchPlaylists(),
        fetchRecentlyPlayed(),
        fetchFavorites(),
      ]);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _initialize() async {
    debugPrint('Initializing AppState');
    state = state.copyWith(isInitialized: true);
    
    try {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        debugPrint('Found existing token, attempting to load user data');
        try {
          // Get user profile first
          final user = await _apiClient.getProfile();
          state = state.copyWith(user: user);
          
          // Defer data loading to avoid build-time state changes
          Future.microtask(() async {
            try {
              // Load characters first since they're needed for chat initialization
              await loadCharacters();
              // Then load other user data
              await Future.wait([
                fetchPlaylists(),
                fetchRecentlyPlayed(),
                fetchFavorites(),
                fetchTracks(),
              ]);
            } catch (e) {
              debugPrint('Error loading user data: $e');
              // If we fail to load data, clear tokens and user state
              await _storageService.clearTokens();
              state = state.copyWith(user: null);
            }
          });
        } catch (e) {
          debugPrint('Error loading user profile: $e');
          await _storageService.clearTokens();
          state = state.copyWith(user: null);
        }
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      await _storageService.clearTokens();
      state = state.copyWith(user: null);
    }
  }

  Future<void> loadCharacters() async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final characters = await _apiClient.getCharacters();
      state = state.copyWith(characters: characters);
      debugPrint('Fetched ${characters.length} characters');
    } on DioException catch (e) {
      debugPrint('Error fetching characters: ${e.message}');
      _setError('Failed to load characters: ${e.message}');
      state = state.copyWith(characters: []);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error fetching characters: $e');
      _setError('Failed to load characters: ${e.toString()}');
      state = state.copyWith(characters: []);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChats() async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final chats = await _apiClient.getChats();
      state = state.copyWith(chats: chats);
      debugPrint('Fetched ${chats.length} chats');
    } on DioException catch (e) {
      debugPrint('Error fetching chats: ${e.message}');
      _setError('Failed to load chats: ${e.message}');
      state = state.copyWith(chats: []);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error fetching chats: $e');
      _setError('Failed to load chats: ${e.toString()}');
      state = state.copyWith(chats: []);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTracks() async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final tracks = await _apiClient.getTracks(skip: 0, limit: 100);
      state = state.copyWith(tracks: tracks);
      debugPrint('Fetched ${tracks.length} tracks');
    } on DioException catch (e) {
      debugPrint('Error fetching tracks: ${e.message}');
      _setError('Failed to load tracks: ${e.message}');
      state = state.copyWith(tracks: []);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error fetching tracks: $e');
      _setError('Failed to load tracks: ${e.toString()}');
      state = state.copyWith(tracks: []);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPlaylists() async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final playlists = await _apiClient.getPlaylists();
      state = state.copyWith(playlists: playlists);
      debugPrint('Fetched ${playlists.length} playlists');
    } on DioException catch (e) {
      debugPrint('Error fetching playlists: ${e.message}');
      _setError('Failed to load playlists: ${e.message}');
      state = state.copyWith(playlists: []);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error fetching playlists: $e');
      _setError('Failed to load playlists: ${e.toString()}');
      state = state.copyWith(playlists: []);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchRecentlyPlayed() async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final recentlyPlayed = await _apiClient.getRecentlyPlayed();
      state = state.copyWith(recentlyPlayed: recentlyPlayed);
      debugPrint('Fetched ${recentlyPlayed.length} recently played items');
    } on DioException catch (e) {
      debugPrint('Error fetching recently played: ${e.message}');
      _setError('Failed to load recently played: ${e.message}');
      state = state.copyWith(recentlyPlayed: []);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error fetching recently played: $e');
      _setError('Failed to load recently played: ${e.toString()}');
      state = state.copyWith(recentlyPlayed: []);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createCharacter(CharacterCreate character) async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      await _apiClient.createCharacter(character);
      await loadCharacters();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFavorites() async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final favorites = await _apiClient.getFavorites();
      state = state.copyWith(favorites: favorites);
      debugPrint('Fetched ${favorites.length} favorites');
    } on DioException catch (e) {
      debugPrint('Error fetching favorites: ${e.message}');
      _setError('Failed to load favorites: ${e.message}');
      state = state.copyWith(favorites: []);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error fetching favorites: $e');
      _setError('Failed to load favorites: ${e.toString()}');
      state = state.copyWith(favorites: []);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChatMessages(String chatId) async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final messages = await _apiClient.getChatMessages(chatId);
      final updatedMessages = Map<String, List<Message>>.from(state.chatMessages);
      updatedMessages[chatId] = messages;
      state = state.copyWith(chatMessages: updatedMessages);
      debugPrint('Fetched ${messages.length} messages for chat $chatId');
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
      _setError('Failed to load chat messages: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Chat?> createChat(String characterId) async {
    if (state.isLoading) return null;
    _setLoading(true);
    _setError(null);
    try {
      final chat = await _apiClient.createChat(characterId);
      final updatedChats = [...state.chats, chat];
      state = state.copyWith(chats: updatedChats);
      debugPrint('Created new chat with character $characterId');
      return chat;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      _setError('Failed to create chat: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendMessage(String chatId, String content) async {
    if (state.isLoading) return;
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiClient.sendMessage(chatId, content);
      debugPrint('=== Send Message Response ===');
      debugPrint('Number of messages: ${response.messages.length}');
      for (final msg in response.messages) {
        debugPrint('Message ID: ${msg.id}');
        debugPrint('Content: ${msg.content}');
        debugPrint('Type: ${msg.type}');
        debugPrint('Is user: ${msg.isUser}');
        debugPrint('Media URL: ${msg.mediaUrl}');
      }
      debugPrint('==========================');
      
      final updatedMessages = Map<String, List<Message>>.from(state.chatMessages);
      final currentMessages = updatedMessages[chatId] ?? [];
      updatedMessages[chatId] = [...currentMessages, ...response.messages];
      state = state.copyWith(chatMessages: updatedMessages);
      debugPrint('Updated chat $chatId with ${response.messages.length} new messages');
    } catch (e) {
      debugPrint('Error sending message: $e');
      _setError('Failed to send message: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppStateData>((ref) {
  try {
    final apiClient = getIt<ApiClient>();
    final storageService = getIt<StorageService>();
    return AppStateNotifier(
      apiClient: apiClient,
      storageService: storageService,
    );
  } catch (e) {
    throw Exception('Failed to initialize AppState: $e');
  }
});
