import 'package:json_annotation/json_annotation.dart';
import '../config/env_config.dart';
import 'package:flutter/foundation.dart';

part 'audio.g.dart';

@JsonSerializable()
class UserInfo {
  final String id;
  final String username;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  UserInfo({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

@JsonSerializable()
class Track {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'audio_url')
  final String audio_url;
  final String artist;
  final double duration;
  @JsonKey(name: 'cover_url')
  final String? cover_url;
  @JsonKey(name: 'gif_url')
  final String? gif_url;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'username')
  final String? username;
  @JsonKey(name: 'user_avatar')
  final String? userAvatar;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Helper methods for full URLs
  String get fullAudioUrl => audio_url.startsWith('http') 
    ? audio_url 
    : '${EnvConfig.apiBaseUrl}/audio/stream/$id';
    
  String? get fullCoverUrl => cover_url == null 
    ? null 
    : cover_url!.startsWith('http') 
      ? cover_url 
      : '${EnvConfig.staticBaseUrl}${cover_url!.startsWith('/') ? cover_url : '/static/images/$cover_url'}';

  String? get fullUserAvatar => userAvatar == null 
    ? null 
    : userAvatar!.startsWith('http') 
      ? userAvatar 
      : '${EnvConfig.staticBaseUrl}${userAvatar!.startsWith('/') ? userAvatar : '/static/images/$userAvatar'}';

  String? get fullGifUrl {
    if (gif_url == null) return null;
    debugPrint('Original gif URL: $gif_url');
    debugPrint('Static base URL: ${EnvConfig.staticBaseUrl}');
    
    // Always treat GIF URLs as relative paths under /static/gif/
    final url = gif_url!.startsWith('/static/gif/') 
        ? '${EnvConfig.staticBaseUrl}$gif_url'
        : '${EnvConfig.staticBaseUrl}/static/gif/${gif_url!.split('/').last}';
    
    debugPrint('Full gif URL: $url');
    return url;
  }

  Track({
    required this.id,
    required this.title,
    this.description,
    required this.audio_url,
    required this.artist,
    required this.duration,
    this.cover_url,
    this.gif_url,
    required this.userId,
    this.username,
    this.userAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    // Convert integer IDs to strings if needed
    final modifiedJson = Map<String, dynamic>.from(json);
    if (json['id'] is int) {
      modifiedJson['id'] = json['id'].toString();
    }
    if (json['user_id'] is int) {
      modifiedJson['user_id'] = json['user_id'].toString();
    }
    return _$TrackFromJson(modifiedJson);
  }
  Map<String, dynamic> toJson() => _$TrackToJson(this);
}


@JsonSerializable()
class RecentlyPlayed {
  final String id;
  final Track track;
  @JsonKey(name: 'track_id')
  final String trackId;
  @JsonKey(name: 'played_at')
  final DateTime playedAt;
  @JsonKey(name: 'user_id', required: false)
  final String? userId;

  RecentlyPlayed({
    required this.id,
    required this.track,
    required this.trackId,
    required this.playedAt,
    this.userId,
  });

  factory RecentlyPlayed.fromJson(Map<String, dynamic> json) {
    // Convert integer IDs to strings if needed
    final modifiedJson = Map<String, dynamic>.from(json);
    if (json['id'] is int) {
      modifiedJson['id'] = json['id'].toString();
    }
    if (json['user_id'] is int) {
      modifiedJson['user_id'] = json['user_id'].toString();
    }
    if (json['track_id'] is int) {
      modifiedJson['track_id'] = json['track_id'].toString();
    }
    return _$RecentlyPlayedFromJson(modifiedJson);
  }
  Map<String, dynamic> toJson() => _$RecentlyPlayedToJson(this);

  // Delegate properties to track for convenience
  String get title => track.title;
  String get description => track.description ?? '';
  String get audio_url => track.audio_url;
  String get artist => track.artist;
  double get duration => track.duration;
  String? get cover_url => track.cover_url;
}

@JsonSerializable()
class PlaylistCreate {
  final String name;
  final String description;

  PlaylistCreate({
    required this.name,
    required this.description,
  });

  factory PlaylistCreate.fromJson(Map<String, dynamic> json) =>
      _$PlaylistCreateFromJson(json);
  Map<String, dynamic> toJson() => _$PlaylistCreateToJson(this);
}

@JsonSerializable()
class PlaylistUpdate {
  final String? name;
  final String? description;

  PlaylistUpdate({
    this.name,
    this.description,
  });

  factory PlaylistUpdate.fromJson(Map<String, dynamic> json) =>
      _$PlaylistUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$PlaylistUpdateToJson(this);
}
