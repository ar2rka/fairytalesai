// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'free_story_reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreeStoryReaction _$FreeStoryReactionFromJson(Map<String, dynamic> json) =>
    FreeStoryReaction(
      id: json['id'] as String,
      freeStoryId: json['free_story_id'] as String,
      userId: json['user_id'] as String,
      reactionType: json['reaction_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$FreeStoryReactionToJson(FreeStoryReaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'free_story_id': instance.freeStoryId,
      'user_id': instance.userId,
      'reaction_type': instance.reactionType,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

FreeStoryReactionStats _$FreeStoryReactionStatsFromJson(
        Map<String, dynamic> json) =>
    FreeStoryReactionStats(
      likesCount: (json['likes_count'] as num).toInt(),
      dislikesCount: (json['dislikes_count'] as num).toInt(),
      userReaction: json['user_reaction'] as String?,
    );

Map<String, dynamic> _$FreeStoryReactionStatsToJson(
        FreeStoryReactionStats instance) =>
    <String, dynamic>{
      'likes_count': instance.likesCount,
      'dislikes_count': instance.dislikesCount,
      'user_reaction': instance.userReaction,
    };
