import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  @JsonKey(fromJson: _stringFromJson)
  final String id;
  @JsonKey(name: 'chat_id', fromJson: _stringFromJson)
  final String chatId;
  @JsonKey(fromJson: _stringFromJson)
  final String content;
  @JsonKey(name: 'created_at', fromJson: _dateFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'is_user')
  final bool isUser;
  @JsonKey(fromJson: _stringFromJson, defaultValue: 'text')
  final String type;
  @JsonKey(fromJson: _doubleFromJson, defaultValue: 0.0)
  final double duration;
  @JsonKey(name: 'thumbnail_url', fromJson: _urlFromJson)
  final String _thumbnailUrl;

  @JsonKey(name: 'media_url', fromJson: _urlFromJson)
  final String _mediaUrl;

  @JsonKey(name: 'audio', ignore: true)
  final dynamic audio;

  String get thumbnailUrl {
    if (_thumbnailUrl.isEmpty) return '';
    if (_thumbnailUrl.startsWith('http')) return _thumbnailUrl;
    if (_thumbnailUrl.startsWith('/')) {
      return '${EnvConfig.staticBaseUrl}$_thumbnailUrl';
    }
    return '${EnvConfig.staticBaseUrl}/static/images/$_thumbnailUrl';
  }

  String get mediaUrl {
    if (_mediaUrl.isEmpty) return '';
    if (_mediaUrl.startsWith('http')) return _mediaUrl;
    if (_mediaUrl.startsWith('/')) {
      return '${EnvConfig.staticBaseUrl}$_mediaUrl';
    }
    return '${EnvConfig.staticBaseUrl}/static/audio/$_mediaUrl';
  }

  static String _stringFromJson(dynamic value) {
    try {
      return value?.toString() ?? '';
    } catch (e) {
      debugPrint('Error converting to string: $e');
      return '';
    }
  }
  
  static DateTime _dateFromJson(dynamic value) {
    try {
      return value == null ? DateTime.now() : DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return DateTime.now();
    }
  }
      
  static double _doubleFromJson(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    } catch (e) {
      debugPrint('Error converting to double: $e');
      return 0.0;
    }
  }
      
  static String _urlFromJson(dynamic value) {
    try {
      if (value == null || value.toString().trim().isEmpty) return '';
      return value.toString().trim();
    } catch (e) {
      debugPrint('Error processing URL: $e');
      debugPrint('Original value: $value');
      return '';
    }
  }

  Message({
    required this.id,
    required this.chatId,
    required this.content,
    required this.createdAt,
    required this.isUser,
    String? type,
    double? duration,
    String? thumbnailUrl,
    String? mediaUrl,
    this.audio,
  })  : this.type = type ?? 'text',
        this.duration = duration ?? 0.0,
        this._thumbnailUrl = thumbnailUrl ?? '',
        this._mediaUrl = mediaUrl ?? '';

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString() ?? '';
      final chatId = json['chat_id']?.toString() ?? '';
      final content = json['content']?.toString() ?? '';
      final createdAt = json['created_at'] == null ? DateTime.now() : DateTime.parse(json['created_at'].toString());
      final isUser = json['is_user'] as bool? ?? false;
      final type = json['type']?.toString() ?? 'text';
      final duration = json['duration'] == null ? 0.0 : Message._doubleFromJson(json['duration']);
      final thumbnailUrl = json['thumbnail_url']?.toString() ?? '';
      final mediaUrl = json['media_url']?.toString() ?? '';

      return Message(
        id: id,
        chatId: chatId,
        content: content,
        createdAt: createdAt,
        isUser: isUser,
        type: type,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      debugPrint('Error parsing message: $e');
      debugPrint('Message data: $json');
      // Return a basic message instance instead of rethrowing
      return Message(
        id: json['id']?.toString() ?? '',
        chatId: json['chat_id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        createdAt: json['created_at'] == null ? DateTime.now() : DateTime.parse(json['created_at'].toString()),
        isUser: json['is_user'] as bool? ?? false,
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_id': chatId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'is_user': isUser,
    'type': type,
    'duration': duration,
    'thumbnail_url': _thumbnailUrl,
    'media_url': _mediaUrl,
  };
}

@JsonSerializable()
class MessageRequest {
  final String content;
  @JsonKey(defaultValue: 'text')
  final String type;

  MessageRequest({
    required this.content,
    String? type,
  }) : this.type = type ?? 'text';

  Map<String, dynamic> toJson() => _$MessageRequestToJson(this);
}

@JsonSerializable()
class MessageResponse {
  @JsonKey(defaultValue: [])
  final List<Message> messages;

  MessageResponse({required this.messages});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json['messages'] == null) {
        debugPrint('No messages in response');
        return MessageResponse(messages: []);
      }
      final messages = (json['messages'] as List<dynamic>)
          .map((messageJson) => Message.fromJson(messageJson as Map<String, dynamic>))
          .toList();
      debugPrint('Parsed ${messages.length} messages');
      return MessageResponse(messages: messages);
    } catch (e) {
      debugPrint('Error parsing message response: $e');
      debugPrint('Response data: $json');
      return MessageResponse(messages: []);
    }
  }
}
