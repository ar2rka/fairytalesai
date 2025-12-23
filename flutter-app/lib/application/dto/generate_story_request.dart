import 'package:json_annotation/json_annotation.dart';

part 'generate_story_request.g.dart';

@JsonSerializable()
class GenerateStoryRequest {
  @JsonKey(name: 'story_type')
  final String storyType;
  @JsonKey(name: 'child_id')
  final String? childId;
  @JsonKey(name: 'hero_id')
  final String? heroId;
  @JsonKey(name: 'story_length')
  final int? storyLength;
  @JsonKey(name: 'hero_appearance')
  final String? heroAppearance;
  @JsonKey(name: 'relationship_description')
  final String? relationshipDescription;
  final String moral;
  final String language;

  GenerateStoryRequest({
    required this.storyType,
    this.childId,
    this.heroId,
    this.storyLength,
    this.heroAppearance,
    this.relationshipDescription,
    required this.moral,
    required this.language,
  });

  factory GenerateStoryRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateStoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateStoryRequestToJson(this);
}

