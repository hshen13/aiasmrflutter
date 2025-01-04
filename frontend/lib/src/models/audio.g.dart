// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
    };

Track _$TrackFromJson(Map<String, dynamic> json) => Track(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      audio_url: json['audio_url'] as String,
      artist: json['artist'] as String,
      duration: (json['duration'] as num).toDouble(),
      cover_url: json['cover_url'] as String?,
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      userAvatar: json['user_avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TrackToJson(Track instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'audio_url': instance.audio_url,
      'artist': instance.artist,
      'duration': instance.duration,
      'cover_url': instance.cover_url,
      'user_id': instance.userId,
      'username': instance.username,
      'user_avatar': instance.userAvatar,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

RecentlyPlayed _$RecentlyPlayedFromJson(Map<String, dynamic> json) =>
    RecentlyPlayed(
      id: json['id'] as String,
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      trackId: json['track_id'] as String,
      playedAt: DateTime.parse(json['played_at'] as String),
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$RecentlyPlayedToJson(RecentlyPlayed instance) =>
    <String, dynamic>{
      'id': instance.id,
      'track': instance.track,
      'track_id': instance.trackId,
      'played_at': instance.playedAt.toIso8601String(),
      'user_id': instance.userId,
    };

PlaylistCreate _$PlaylistCreateFromJson(Map<String, dynamic> json) =>
    PlaylistCreate(
      name: json['name'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$PlaylistCreateToJson(PlaylistCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };

PlaylistUpdate _$PlaylistUpdateFromJson(Map<String, dynamic> json) =>
    PlaylistUpdate(
      name: json['name'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PlaylistUpdateToJson(PlaylistUpdate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };
