import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import 'message.dart';
import 'character.dart';

part 'chat.g.dart';

@JsonSerializable()
class Chat {
  @JsonKey(fromJson: _stringFromJson)
  final String id;
  @JsonKey(name: 'user_id', fromJson: _stringFromJson)
  final String userId;
  @JsonKey(name: 'character_id', fromJson: _stringFromJson)
  final String characterId;
  @JsonKey(fromJson: _stringFromJson, defaultValue: '')
  final String title;
  @JsonKey(fromJson: _stringFromJson, defaultValue: '')
  final String description;
  @JsonKey(fromJson: _characterFromJson)
  final Character? character;
  @JsonKey(name: 'last_message', fromJson: _messageFromJson)
  final Message? lastMessage;
  @JsonKey(defaultValue: [])
  final List<Message> messages;
  @JsonKey(name: 'created_at', fromJson: _dateFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateFromJson)
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.userId,
    required this.characterId,
    String? title,
    String? description,
    this.character,
    this.lastMessage,
    List<Message>? messages,
    required this.createdAt,
    required this.updatedAt,
  }) : this.messages = messages ?? const [],
       this.title = title ?? '',
       this.description = description ?? '';

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
  Map<String, dynamic> toJson() => _$ChatToJson(this);

  // Helper methods to convert dynamic types
  static String _stringFromJson(dynamic value) => value?.toString() ?? '';
  
  static DateTime _dateFromJson(dynamic value) => 
      value == null ? DateTime.now() : DateTime.parse(value.toString());
      
  static Character? _characterFromJson(dynamic json) {
    if (json == null) return null;
    try {
      if (json is Map<String, dynamic>) {
        return Character.fromJson(json);
      } else {
        debugPrint('Invalid character data type: ${json.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('Error parsing character: $e');
      debugPrint('Character data: $json');
      return null;
    }
  }
  
  static Message? _messageFromJson(dynamic json) {
    if (json == null) return null;
    try {
      if (json is Map<String, dynamic>) {
        return Message.fromJson(json);
      } else {
        debugPrint('Invalid message data type: ${json.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
      debugPrint('Message data: $json');
      return null;
    }
  }

  String get characterName => character?.name ?? title;
  String get characterAvatar => character?.avatarOrImageUrl ?? '';
  String get lastMessageText => lastMessage?.content ?? '';
}
