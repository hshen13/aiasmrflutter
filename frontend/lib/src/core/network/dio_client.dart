import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../storage/storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  late final Dio _dio;
  final StorageService _storageService;

  // Get the appropriate host based on platform and environment
  String get _host {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android emulator to reach host machine's localhost
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // Use localhost for iOS simulator
      return 'http://localhost:8000';
    } else {
      // Default to localhost for other platforms
      return 'http://localhost:8000';
    }
  }

  String get _baseUrl => _host;

  DioClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add origin header for CORS
          'Origin': _host,
        },
      ),
    )
      ..interceptors.add(AuthInterceptor(_storageService))
      ..interceptors.add(LoggingInterceptor())
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('*** API Request - Start ***');
            debugPrint('URI: ${options.uri}');
            debugPrint('METHOD: ${options.method}');
            debugPrint('HEADERS: ${options.headers}');
            debugPrint('QUERY PARAMETERS: ${options.queryParameters}');
            debugPrint('BODY: ${options.data}');
            debugPrint('*** API Request - End ***');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('*** API Response - Start ***');
            debugPrint('URI: ${response.requestOptions.uri}');
            debugPrint('STATUS CODE: ${response.statusCode}');
            debugPrint('BODY: ${response.data}');
            debugPrint('*** API Response - End ***');
            return handler.next(response);
          },
          onError: (DioException e, handler) async {
            debugPrint('*** API Error - Start ***');
            debugPrint('URI: ${e.requestOptions.uri}');
            debugPrint('METHOD: ${e.requestOptions.method}');
            debugPrint('STATUS CODE: ${e.response?.statusCode}');
            debugPrint('ERROR TYPE: ${e.type}');
            debugPrint('ERROR MESSAGE: ${e.message}');
            debugPrint('ERROR: ${e.error}');
            debugPrint('STACK TRACE: ${e.stackTrace}');
            debugPrint('*** API Error - End ***');

            // Handle connection errors
            if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionError) {
              final message = Platform.isAndroid
                  ? 'Unable to connect to server. Please ensure the backend server is running on your development machine.'
                  : 'Unable to connect to server. Please check if the server is running and try again.';
              return handler.next(DioException(
                requestOptions: e.requestOptions,
                error: message,
                type: e.type,
              ));
            }

            // Handle 401 Unauthorized
            if (e.response?.statusCode == 401) {
              try {
                final refreshToken = await _storageService.getRefreshToken();
                if (refreshToken == null) {
                  debugPrint('No refresh token found');
                  return handler.next(e);
                }

                // Create a new Dio instance for refresh request
                final refreshDio = Dio(BaseOptions(
                  baseUrl: _baseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Origin': _host,
                  },
                ));

                final refreshResponse = await refreshDio.post(
                  '/api/v1/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  debugPrint('Token refresh successful');
                  await _storageService.setAccessToken(refreshResponse.data['access_token']);
                  await _storageService.setRefreshToken(refreshResponse.data['refresh_token']);

                  // Retry original request
                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer ${refreshResponse.data['access_token']}';
                  
                  try {
                    debugPrint('Retrying original request');
                    final response = await _dio.fetch(options);
                    return handler.resolve(response);
                  } catch (retryError) {
                    debugPrint('Error retrying request: $retryError');
                    return handler.next(e);
                  }
                }
              } catch (refreshError) {
                debugPrint('Error during token refresh: $refreshError');
                await _storageService.clearTokens();
                return handler.next(e);
              }
            }

            return handler.next(e);
          },
        ),
      );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      debugPrint('GET request failed for $path: $e');
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      debugPrint('POST request failed for $path: $e');
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      debugPrint('PUT request failed for $path: $e');
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      debugPrint('DELETE request failed for $path: $e');
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      debugPrint('PATCH request failed for $path: $e');
      rethrow;
    }
  }
}
