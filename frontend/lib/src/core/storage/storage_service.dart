import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_keys.dart';

abstract class StorageService {
  Future<void> init();
  Future<void> clear();
  
  // Auth
  Future<String?> getAccessToken();
  Future<void> setAccessToken(String token);
  Future<String?> getRefreshToken();
  Future<void> setRefreshToken(String token);
  Future<void> clearTokens();
  Future<void> saveTokens({required String accessToken, required String refreshToken});

  // Theme
  Future<bool> getDarkMode();
  Future<void> setDarkMode(bool value);

  // Audio
  Future<List<String>> getFavoritePlaylistIds();
  Future<void> addFavoritePlaylistId(String id);
  Future<void> removeFavoritePlaylistId(String id);
  
  Future<List<String>> getRecentlyPlayedIds();
  Future<void> addRecentlyPlayedId(String id);
  Future<void> removeRecentlyPlayedId(String id);

  // Favorites
  Future<List<String>?> getFavorites();
  Future<void> setFavorites(List<String> favorites);
}

class SharedPreferencesService implements StorageService {
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    try {
      debugPrint('Initializing SharedPreferencesService');
      _prefs = await SharedPreferences.getInstance();
      debugPrint('SharedPreferencesService initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing SharedPreferencesService: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      debugPrint('Clearing all stored preferences');
      await _prefs.clear();
      debugPrint('Successfully cleared all preferences');
    } catch (e, stackTrace) {
      debugPrint('Error clearing preferences: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final token = _prefs.getString(StorageKeys.accessToken);
      debugPrint('Retrieved access token: ${token != null ? '[PRESENT]' : '[NOT FOUND]'}');
      return token;
    } catch (e, stackTrace) {
      debugPrint('Error getting access token: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setAccessToken(String token) async {
    try {
      debugPrint('Setting access token');
      await _prefs.setString(StorageKeys.accessToken, token);
      debugPrint('Access token set successfully');
    } catch (e, stackTrace) {
      debugPrint('Error setting access token: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      final token = _prefs.getString(StorageKeys.refreshToken);
      debugPrint('Retrieved refresh token: ${token != null ? '[PRESENT]' : '[NOT FOUND]'}');
      return token;
    } catch (e, stackTrace) {
      debugPrint('Error getting refresh token: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setRefreshToken(String token) async {
    try {
      debugPrint('Setting refresh token');
      await _prefs.setString(StorageKeys.refreshToken, token);
      debugPrint('Refresh token set successfully');
    } catch (e, stackTrace) {
      debugPrint('Error setting refresh token: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      debugPrint('Saving tokens');
      await Future.wait([
        setAccessToken(accessToken),
        setRefreshToken(refreshToken),
      ]);
      debugPrint('Tokens saved successfully');
    } catch (e, stackTrace) {
      debugPrint('Error saving tokens: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      debugPrint('Clearing all tokens');
      await _prefs.remove(StorageKeys.accessToken);
      await _prefs.remove(StorageKeys.refreshToken);
      debugPrint('All tokens cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('Error clearing tokens: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<bool> getDarkMode() async {
    try {
      final isDarkMode = _prefs.getBool(StorageKeys.darkMode) ?? false;
      debugPrint('Retrieved dark mode setting: $isDarkMode');
      return isDarkMode;
    } catch (e, stackTrace) {
      debugPrint('Error getting dark mode setting: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setDarkMode(bool value) async {
    try {
      debugPrint('Setting dark mode to: $value');
      await _prefs.setBool(StorageKeys.darkMode, value);
      debugPrint('Dark mode set successfully');
    } catch (e, stackTrace) {
      debugPrint('Error setting dark mode: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<String>> getFavoritePlaylistIds() async {
    try {
      final favorites = _prefs.getStringList(StorageKeys.favoritePlaylists) ?? [];
      debugPrint('Retrieved ${favorites.length} favorite playlist IDs');
      return favorites;
    } catch (e, stackTrace) {
      debugPrint('Error getting favorite playlist IDs: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> addFavoritePlaylistId(String id) async {
    try {
      debugPrint('Adding playlist ID to favorites: $id');
      final favorites = await getFavoritePlaylistIds();
      if (!favorites.contains(id)) {
        favorites.add(id);
        await _prefs.setStringList(StorageKeys.favoritePlaylists, favorites);
        debugPrint('Playlist ID added to favorites successfully');
      } else {
        debugPrint('Playlist ID already in favorites');
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding favorite playlist ID: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> removeFavoritePlaylistId(String id) async {
    try {
      debugPrint('Removing playlist ID from favorites: $id');
      final favorites = await getFavoritePlaylistIds();
      favorites.remove(id);
      await _prefs.setStringList(StorageKeys.favoritePlaylists, favorites);
      debugPrint('Playlist ID removed from favorites successfully');
    } catch (e, stackTrace) {
      debugPrint('Error removing favorite playlist ID: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<String>> getRecentlyPlayedIds() async {
    try {
      final recentlyPlayed = _prefs.getStringList(StorageKeys.recentlyPlayed) ?? [];
      debugPrint('Retrieved ${recentlyPlayed.length} recently played IDs');
      return recentlyPlayed;
    } catch (e, stackTrace) {
      debugPrint('Error getting recently played IDs: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> addRecentlyPlayedId(String id) async {
    try {
      debugPrint('Adding ID to recently played: $id');
      final recentlyPlayed = await getRecentlyPlayedIds();
      recentlyPlayed.remove(id); // Remove if exists to move to front
      recentlyPlayed.insert(0, id); // Add to front
      if (recentlyPlayed.length > 50) {
        recentlyPlayed.removeLast(); // Keep only last 50
      }
      await _prefs.setStringList(StorageKeys.recentlyPlayed, recentlyPlayed);
      debugPrint('ID added to recently played successfully');
    } catch (e, stackTrace) {
      debugPrint('Error adding recently played ID: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> removeRecentlyPlayedId(String id) async {
    try {
      debugPrint('Removing ID from recently played: $id');
      final recentlyPlayed = await getRecentlyPlayedIds();
      recentlyPlayed.remove(id);
      await _prefs.setStringList(StorageKeys.recentlyPlayed, recentlyPlayed);
      debugPrint('ID removed from recently played successfully');
    } catch (e, stackTrace) {
      debugPrint('Error removing recently played ID: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<String>?> getFavorites() async {
    try {
      final favorites = _prefs.getStringList(StorageKeys.favoriteAudios);
      debugPrint('Retrieved favorites: $favorites');
      return favorites;
    } catch (e, stackTrace) {
      debugPrint('Error getting favorites: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> setFavorites(List<String> favorites) async {
    try {
      debugPrint('Setting favorites: $favorites');
      await _prefs.setStringList(StorageKeys.favoriteAudios, favorites);
      debugPrint('Favorites set successfully');
    } catch (e, stackTrace) {
      debugPrint('Error setting favorites: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
