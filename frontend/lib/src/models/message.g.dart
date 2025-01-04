// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: Message._stringFromJson(json['id']),
      chatId: Message._stringFromJson(json['chat_id']),
      content: Message._stringFromJson(json['content']),
      createdAt: Message._dateFromJson(json['created_at']),
      isUser: json['is_user'] as bool,
      type:
          json['type'] == null ? 'text' : Message._stringFromJson(json['type']),
      duration: json['duration'] == null
          ? 0.0
          : Message._doubleFromJson(json['duration']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'chat_id': instance.chatId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'is_user': instance.isUser,
      'type': instance.type,
      'duration': instance.duration,
      'thumbnailUrl': instance.thumbnailUrl,
      'mediaUrl': instance.mediaUrl,
    };

MessageRequest _$MessageRequestFromJson(Map<String, dynamic> json) =>
    MessageRequest(
      content: json['content'] as String,
      type: json['type'] as String? ?? 'text',
    );

Map<String, dynamic> _$MessageRequestToJson(MessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'type': instance.type,
    };

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'messages': instance.messages,
    };
