import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

part 'character.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Character {
  @JsonKey(fromJson: _stringFromJson)
  final String id;
  @JsonKey(fromJson: _stringFromJson)
  final String name;
  @JsonKey(fromJson: _stringFromJson)
  final String description;
  @JsonKey(name: 'avatar_url', fromJson: _urlFromJson, defaultValue: '')
  final String avatarUrl;
  @JsonKey(name: 'image_url', fromJson: _urlFromJson, defaultValue: '')
  final String imageUrl;
  @JsonKey(name: 'system_prompt', fromJson: _stringFromJson, defaultValue: '')
  final String systemPrompt;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at', fromJson: _dateFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateFromJson)
  final DateTime updatedAt;
  @JsonKey(name: 'creator_id', fromJson: _stringFromJson, defaultValue: '')
  final String creatorId;
  @JsonKey(name: 'creator_name', fromJson: _stringFromJson, defaultValue: 'system')
  final String creatorName;
  @JsonKey(name: 'sample_contents', defaultValue: [])
  final List<String> sampleContents;
  @JsonKey(name: 'sample_video_urls', defaultValue: [])
  final List<String> sampleVideoUrls;
  @JsonKey(name: 'sample_audio_url', fromJson: _urlFromJson)
  final String? sampleAudioUrl;

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
  
  static String _urlFromJson(dynamic value) {
    try {
      if (value == null) return '';
      final url = value.toString();
      if (url.isEmpty) return '';
      
      // Return as-is if it's already an absolute URL
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      
      // Handle relative paths
      return '${EnvConfig.staticBaseUrl}${url.startsWith('/') ? url : '/$url'}';
    } catch (e) {
      debugPrint('Error processing URL: $e');
      return '';
    }
  }

  Character({
    required this.id,
    required this.name,
    required this.description,
    String? avatarUrl,
    String? imageUrl,
    String? systemPrompt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    String? creatorId,
    String? creatorName,
    List<String>? sampleContents,
    List<String>? sampleVideoUrls,
    this.sampleAudioUrl,
  })  : this.avatarUrl = avatarUrl ?? '',
        this.imageUrl = imageUrl ?? '',
        this.systemPrompt = systemPrompt ?? '',
        this.creatorId = creatorId ?? '',
        this.creatorName = creatorName ?? 'system',
        this.sampleContents = sampleContents ?? [],
        this.sampleVideoUrls = sampleVideoUrls ?? [];

  // Helper getters
  String get avatarOrImageUrl {
    if (avatarUrl.isNotEmpty) return avatarUrl;
    if (imageUrl.isNotEmpty) return imageUrl;
    return '';
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    try {
      return _$CharacterFromJson(json);
    } catch (e) {
      debugPrint('Error parsing character: $e');
      debugPrint('Character data: $json');
      // Return null instead of rethrowing to prevent app crashes
      return Character(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now()
      );
    }
  }
  
  Map<String, dynamic> toJson() => _$CharacterToJson(this);

  int get interactions => metadata?['interactions'] ?? 0;
  int get onlineTime => metadata?['followers'] ?? 347;
  String get username => metadata?['username'] as String? ?? name.toLowerCase();
  String get shortBio => metadata?['short_bio'] as String? ?? description;
  String get waveformUrl => _urlFromJson(metadata?['waveform_url'] ?? '/static/images/waveform.png');
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CharacterCreate {
  final String name;
  final String description;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final Map<String, dynamic>? metadata;

  CharacterCreate({
    required this.name,
    required this.description,
    this.avatarUrl,
    this.metadata,
  });

  factory CharacterCreate.fromJson(Map<String, dynamic> json) =>
      _$CharacterCreateFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterCreateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CharacterUpdate {
  final String? name;
  final String? description;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final Map<String, dynamic>? metadata;

  CharacterUpdate({
    this.name,
    this.description,
    this.avatarUrl,
    this.metadata,
  });

  factory CharacterUpdate.fromJson(Map<String, dynamic> json) =>
      _$CharacterUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterUpdateToJson(this);
}
