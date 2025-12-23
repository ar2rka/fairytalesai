import 'package:json_annotation/json_annotation.dart';

part 'free_story_reaction.g.dart';

enum ReactionType {
  like,
  dislike;

  String get value {
    switch (this) {
      case ReactionType.like:
        return 'like';
      case ReactionType.dislike:
        return 'dislike';
    }
  }

  static ReactionType fromString(String value) {
    switch (value) {
      case 'like':
        return ReactionType.like;
      case 'dislike':
        return ReactionType.dislike;
      default:
        throw ArgumentError('Invalid reaction type: $value');
    }
  }
}

@JsonSerializable()
class FreeStoryReaction {
  final String id;
  @JsonKey(name: 'free_story_id')
  final String freeStoryId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'reaction_type')
  final String reactionType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  FreeStoryReaction({
    required this.id,
    required this.freeStoryId,
    required this.userId,
    required this.reactionType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FreeStoryReaction.fromJson(Map<String, dynamic> json) =>
      _$FreeStoryReactionFromJson(json);

  Map<String, dynamic> toJson() => _$FreeStoryReactionToJson(this);

  ReactionType get reactionTypeEnum => ReactionType.fromString(reactionType);
}

@JsonSerializable()
class FreeStoryReactionStats {
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @JsonKey(name: 'dislikes_count')
  final int dislikesCount;
  @JsonKey(name: 'user_reaction')
  final String? userReaction;

  FreeStoryReactionStats({
    required this.likesCount,
    required this.dislikesCount,
    this.userReaction,
  });

  factory FreeStoryReactionStats.fromJson(Map<String, dynamic> json) =>
      _$FreeStoryReactionStatsFromJson(json);

  Map<String, dynamic> toJson() => _$FreeStoryReactionStatsToJson(this);

  ReactionType? get userReactionEnum =>
      userReaction != null ? ReactionType.fromString(userReaction!) : null;
}

