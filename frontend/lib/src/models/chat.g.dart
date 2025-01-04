// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chat _$ChatFromJson(Map<String, dynamic> json) => Chat(
      id: Chat._stringFromJson(json['id']),
      userId: Chat._stringFromJson(json['user_id']),
      characterId: Chat._stringFromJson(json['character_id']),
      title: json['title'] == null ? '' : Chat._stringFromJson(json['title']),
      description: json['description'] == null
          ? ''
          : Chat._stringFromJson(json['description']),
      character: Chat._characterFromJson(json['character']),
      lastMessage: Chat._messageFromJson(json['last_message']),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: Chat._dateFromJson(json['created_at']),
      updatedAt: Chat._dateFromJson(json['updated_at']),
    );

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'character_id': instance.characterId,
      'title': instance.title,
      'description': instance.description,
      'character': instance.character,
      'last_message': instance.lastMessage,
      'messages': instance.messages,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
