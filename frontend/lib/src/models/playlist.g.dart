// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => Playlist(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      creatorName: json['creator_name'] as String,
      coverUrl: json['coverUrl'] as String?,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
      trackCount: (json['track_count'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'creator_name': instance.creatorName,
      'tracks': instance.tracks,
      'track_count': instance.trackCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'user_id': instance.userId,
      'coverUrl': instance.coverUrl,
    };
