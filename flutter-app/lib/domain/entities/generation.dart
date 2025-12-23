import 'package:json_annotation/json_annotation.dart';
import '../value_objects/generation_status.dart';
import '../value_objects/story_type.dart';

part 'generation.g.dart';

@JsonSerializable()
class Generation {
  @JsonKey(name: 'generation_id')
  final String generationId;
  @JsonKey(name: 'attempt_number')
  final int attemptNumber;
  @JsonKey(name: 'model_used')
  final String modelUsed;
  @JsonKey(name: 'full_response')
  final Map<String, dynamic>? fullResponse;
  final String status;
  final String prompt;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'story_type')
  final String storyType;
  @JsonKey(name: 'story_length')
  final int? storyLength;
  @JsonKey(name: 'hero_appearance')
  final String? heroAppearance;
  @JsonKey(name: 'relationship_description')
  final String? relationshipDescription;
  final String moral;
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  Generation({
    required this.generationId,
    required this.attemptNumber,
    required this.modelUsed,
    this.fullResponse,
    required this.status,
    required this.prompt,
    required this.userId,
    required this.storyType,
    this.storyLength,
    this.heroAppearance,
    this.relationshipDescription,
    required this.moral,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  factory Generation.fromJson(Map<String, dynamic> json) =>
      _$GenerationFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationToJson(this);

  GenerationStatus get statusEnum => GenerationStatus.fromString(status);
  StoryType get storyTypeEnum => StoryType.fromString(storyType);
}

