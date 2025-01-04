import 'package:flutter/foundation.dart';
import 'user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing AuthResponse from JSON: ${json.toString()}');
      
      if (!json.containsKey('access_token')) {
        throw FormatException('Missing access_token in auth response');
      }
      if (!json.containsKey('refresh_token')) {
        throw FormatException('Missing refresh_token in auth response');
      }
      if (!json.containsKey('token_type')) {
        throw FormatException('Missing token_type in auth response');
      }
      if (!json.containsKey('user')) {
        throw FormatException('Missing user data in auth response');
      }

      final userJson = json['user'];
      if (userJson is! Map<String, dynamic>) {
        throw FormatException('Invalid user data format in auth response');
      }

      final response = AuthResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String,
        user: User.fromJson(userJson),
      );

      debugPrint('Successfully parsed AuthResponse');
      debugPrint('Token type: ${response.tokenType}');
      debugPrint('User ID: ${response.user.id}');
      debugPrint('Username: ${response.user.username}');

      return response;
    } catch (e, stackTrace) {
      debugPrint('Error parsing AuthResponse: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Raw JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': tokenType,
        'user': user.toJson(),
      };
    } catch (e, stackTrace) {
      debugPrint('Error converting AuthResponse to JSON: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'AuthResponse(tokenType: $tokenType, user: $user)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResponse &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          tokenType == other.tokenType &&
          user == other.user;

  @override
  int get hashCode =>
      accessToken.hashCode ^
      refreshToken.hashCode ^
      tokenType.hashCode ^
      user.hashCode;
}
