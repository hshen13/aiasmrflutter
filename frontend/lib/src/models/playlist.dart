import 'package:json_annotation/json_annotation.dart';
import '../config/env_config.dart';
import 'audio.dart';

part 'playlist.g.dart';

@JsonSerializable()
class Playlist {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'creator_name')
  final String creatorName;
  @JsonKey(name: 'cover_url')
  final String? _coverUrl;
  final List<Track> tracks;
  @JsonKey(name: 'track_count')
  final int trackCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'user_id', required: false)
  final String? userId;

  String? get coverUrl => _coverUrl == null 
    ? null 
    : _coverUrl!.startsWith('http') 
      ? _coverUrl 
      : '${EnvConfig.staticBaseUrl}${_coverUrl!.startsWith('/') ? _coverUrl : '/static/images/$_coverUrl'}';

  Playlist({
    required this.id,
    required this.title,
    this.description,
    required this.creatorName,
    String? coverUrl,
    required this.tracks,
    required this.trackCount,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
  }) : _coverUrl = coverUrl;

  static String _stringFromJson(dynamic value) {
    try {
      return value?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  static DateTime _dateFromJson(dynamic value) {
    try {
      return value == null ? DateTime.now() : DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    // Convert integer IDs to strings if needed
    final modifiedJson = Map<String, dynamic>.from(json);
    if (json['id'] is int) {
      modifiedJson['id'] = json['id'].toString();
    }
    if (json['user_id'] is int) {
      modifiedJson['user_id'] = json['user_id'].toString();
    }
    return _$PlaylistFromJson(modifiedJson);
  }
  Map<String, dynamic> toJson() => _$PlaylistToJson(this);
}
