import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../storage/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  bool _isRefreshing = false;

  AuthInterceptor(this._storageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    debugPrint('AuthInterceptor - Processing request: ${options.uri}');
    
    // Skip token for login, register, and refresh
    if (options.path.contains('/api/v1/auth/login') || 
        options.path.contains('/api/v1/auth/signup') ||
        options.path.contains('/api/v1/auth/refresh') ||
        options.path.contains('/api/v1/auth/logout')) {
      debugPrint('AuthInterceptor - Skipping auth token for auth endpoint');
      handler.next(options);
      return;
    }

    try {
      final token = await _storageService.getAccessToken();
      debugPrint('AuthInterceptor - Token status: ${token != null ? 'Found' : 'Not found'}');
      
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('AuthInterceptor - Added token to request headers');
      } else {
        debugPrint('AuthInterceptor - No token available');
      }
      
      return handler.next(options);
    } catch (e) {
      debugPrint('AuthInterceptor - Error processing request: $e');
      return handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('AuthInterceptor - Response received: ${response.statusCode}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('AuthInterceptor - Error intercepted: ${err.type}');
    
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      debugPrint('AuthInterceptor - Attempting to refresh token');
      _isRefreshing = true;

      try {
        final refreshToken = await _storageService.getRefreshToken();
        debugPrint('Retrieved refresh token: ${refreshToken != null ? '[FOUND]' : '[NOT FOUND]'}');
        
        if (refreshToken == null) {
          debugPrint('AuthInterceptor - No refresh token available');
          await _handleAuthError();
          return handler.next(err);
        }

        final dio = Dio(BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

        final refreshResponse = await dio.post(
          '/api/v1/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        if (refreshResponse.statusCode == 200) {
          debugPrint('AuthInterceptor - Token refresh successful');
          
          // Store new tokens
          await _storageService.setAccessToken(refreshResponse.data['access_token']);
          await _storageService.setRefreshToken(refreshResponse.data['refresh_token']);

          // Retry original request
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${refreshResponse.data['access_token']}';

          try {
            debugPrint('AuthInterceptor - Retrying original request');
            final response = await dio.fetch(options);
            _isRefreshing = false;
            return handler.resolve(response);
          } catch (retryError) {
            debugPrint('AuthInterceptor - Error retrying request: $retryError');
            await _handleAuthError();
            _isRefreshing = false;
            return handler.next(err);
          }
        } else {
          debugPrint('AuthInterceptor - Token refresh failed');
          await _handleAuthError();
          _isRefreshing = false;
          return handler.next(err);
        }
      } catch (refreshError) {
        debugPrint('AuthInterceptor - Error during token refresh: $refreshError');
        await _handleAuthError();
        _isRefreshing = false;
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<void> _handleAuthError() async {
    debugPrint('AuthInterceptor - Handling auth error');
    await _storageService.clearTokens();
  }
}
