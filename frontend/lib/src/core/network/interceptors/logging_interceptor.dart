import 'package:dio/dio.dart';
import '../../../config/env_config.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (EnvConfig.enableLogging) {
      print('*** API Request - Start ***');
      print('URI: ${options.uri}');
      print('METHOD: ${options.method}');
      print('HEADERS: ${options.headers}');
      print('QUERY PARAMETERS: ${options.queryParameters}');
      print('BODY: ${options.data}');
      print('*** API Request - End ***');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (EnvConfig.enableLogging) {
      print('*** API Response - Start ***');
      print('URI: ${response.requestOptions.uri}');
      print('STATUS CODE: ${response.statusCode}');
      print('HEADERS: ${response.headers}');
      print('BODY: ${response.data}');
      print('*** API Response - End ***');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (EnvConfig.enableLogging) {
      print('*** API Error - Start ***');
      print('URI: ${err.requestOptions.uri}');
      print('METHOD: ${err.requestOptions.method}');
      print('STATUS CODE: ${err.response?.statusCode}');
      print('ERROR TYPE: ${err.type}');
      print('ERROR MESSAGE: ${err.message}');
      if (err.response != null) {
        print('RESPONSE DATA: ${err.response?.data}');
      }
      if (err.error != null) {
        print('ERROR: ${err.error}');
      }
      print('STACK TRACE:');
      print(err.stackTrace);
      print('*** API Error - End ***');
    }
    handler.next(err);
  }
}
