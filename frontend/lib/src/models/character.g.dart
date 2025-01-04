// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Character _$CharacterFromJson(Map<String, dynamic> json) => Character(
      id: Character._stringFromJson(json['id']),
      name: Character._stringFromJson(json['name']),
      description: Character._stringFromJson(json['description']),
      avatarUrl: json['avatar_url'] == null
          ? ''
          : Character._urlFromJson(json['avatar_url']),
      imageUrl: json['image_url'] == null
          ? ''
          : Character._urlFromJson(json['image_url']),
      systemPrompt: json['system_prompt'] == null
          ? ''
          : Character._stringFromJson(json['system_prompt']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: Character._dateFromJson(json['created_at']),
      updatedAt: Character._dateFromJson(json['updated_at']),
      creatorId: json['creator_id'] == null
          ? ''
          : Character._stringFromJson(json['creator_id']),
      creatorName: json['creator_name'] == null
          ? 'system'
          : Character._stringFromJson(json['creator_name']),
      sampleContents: (json['sample_contents'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sampleVideoUrls: (json['sample_video_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sampleAudioUrl: Character._urlFromJson(json['sample_audio_url']),
    );

Map<String, dynamic> _$CharacterToJson(Character instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'avatar_url': instance.avatarUrl,
      'image_url': instance.imageUrl,
      'system_prompt': instance.systemPrompt,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'creator_id': instance.creatorId,
      'creator_name': instance.creatorName,
      'sample_contents': instance.sampleContents,
      'sample_video_urls': instance.sampleVideoUrls,
      'sample_audio_url': instance.sampleAudioUrl,
    };

CharacterCreate _$CharacterCreateFromJson(Map<String, dynamic> json) =>
    CharacterCreate(
      name: json['name'] as String,
      description: json['description'] as String,
      avatarUrl: json['avatar_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CharacterCreateToJson(CharacterCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'avatar_url': instance.avatarUrl,
      'metadata': instance.metadata,
    };

CharacterUpdate _$CharacterUpdateFromJson(Map<String, dynamic> json) =>
    CharacterUpdate(
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CharacterUpdateToJson(CharacterUpdate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'avatar_url': instance.avatarUrl,
      'metadata': instance.metadata,
    };
