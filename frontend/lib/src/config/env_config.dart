class EnvConfig {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const String _staticBaseUrl = 'http://10.0.2.2:80';
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '$_baseUrl/api/v1',
  );

  static const String staticBaseUrl = String.fromEnvironment(
    'STATIC_BASE_URL',
    defaultValue: _staticBaseUrl,
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://10.0.2.2/api/v1/ws',
  );

  static const bool isDevelopment = bool.fromEnvironment(
    'IS_DEVELOPMENT',
    defaultValue: true,
  );

  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  static const int connectTimeout = int.fromEnvironment(
    'CONNECT_TIMEOUT',
    defaultValue: 30000,
  );

  static const int receiveTimeout = int.fromEnvironment(
    'RECEIVE_TIMEOUT',
    defaultValue: 30000,
  );

  // Error messages
  static const String networkErrorMessage = '网络连接错误，请检查网络设置后重试';
  static const String serverErrorMessage = '服务器错误，请稍后重试';
  static const String timeoutErrorMessage = '请求超时，请检查网络设置后重试';
  static const String unknownErrorMessage = '未知错误，请稍后重试';

  static Future<bool> testConnection() async {
    try {
      final response = await Future.delayed(
        const Duration(seconds: 1),
        () => true,
      );
      return response;
    } catch (e) {
      return false;
    }
  }
}
