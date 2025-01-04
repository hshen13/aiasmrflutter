import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

class User {
  String get fullAvatarUrl => avatarUrl == null 
    ? '' 
    : avatarUrl!.startsWith('http') 
      ? avatarUrl! 
      : '${EnvConfig.staticBaseUrl}${avatarUrl!.startsWith('/') ? avatarUrl : '/static/images/$avatarUrl'}';

  final String id;
  final String username;
  final bool isActive;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.isActive,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: (json['id'] ?? '').toString(),
        username: json['username'] as String,
        isActive: json['is_active'] as bool? ?? true,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      debugPrint('Error parsing User from JSON: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'username': username,
        'is_active': isActive,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error converting User to JSON: $e');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now().toUtc();
    }

    if (value is DateTime) {
      return value.toUtc();
    }

    if (value is String) {
      try {
        // Handle different datetime formats
        if (value.endsWith('Z')) {
          // Already in UTC format
          return DateTime.parse(value).toUtc();
        } else if (value.contains('+')) {
          // Contains timezone offset
          return DateTime.parse(value).toUtc();
        } else {
          // Assume UTC if no timezone specified
          return DateTime.parse(value + 'Z').toUtc();
        }
      } catch (e) {
        debugPrint('Error parsing datetime string: $value');
        debugPrint('Error details: $e');
        return DateTime.now().toUtc();
      }
    }

    debugPrint('Unexpected datetime value type: ${value.runtimeType}');
    return DateTime.now().toUtc();
  }

  @override
  String toString() => 'User(id: $id, username: $username, isActive: $isActive, avatarUrl: $avatarUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          isActive == other.isActive;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ isActive.hashCode;

  User copyWith({
    String? id,
    String? username,
    bool? isActive,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
