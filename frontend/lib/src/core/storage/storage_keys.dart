/// Storage keys used by the SharedPreferencesService
class StorageKeys {
  // Auth
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  
  // Theme
  static const darkMode = 'dark_mode';
  
  // Audio
  static const favoritePlaylists = 'favorite_playlists';
  static const recentlyPlayed = 'recently_played';
  static const favoriteAudios = 'favorite_audios';
  
  // Prevent instantiation
  StorageKeys._();
  
  /// Print all storage keys for debugging
  static void debugPrintKeys() {
    print('Storage Keys:');
    print('- Auth:');
    print('  * $accessToken');
    print('  * $refreshToken');
    print('- Theme:');
    print('  * $darkMode');
    print('- Audio:');
    print('  * $favoritePlaylists');
    print('  * $recentlyPlayed');
    print('  * $favoriteAudios');
  }
}
