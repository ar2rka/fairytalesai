import 'package:json_annotation/json_annotation.dart';
import '../value_objects/language.dart';
import '../value_objects/gender.dart';

part 'story.g.dart';

@JsonSerializable()
class Story {
  final String? id;
  final String title;
  final String content;
  final String? summary;
  final String language;
  @JsonKey(name: 'child_id')
  final String? childId;
  @JsonKey(name: 'child_name')
  final String? childName;
  @JsonKey(name: 'child_age')
  final int? childAge;
  @JsonKey(name: 'child_gender')
  final String? childGender;
  @JsonKey(name: 'child_interests')
  final List<String>? childInterests;
  @JsonKey(name: 'hero_id')
  final String? heroId;
  @JsonKey(name: 'hero_name')
  final String? heroName;
  @JsonKey(name: 'hero_gender')
  final String? heroGender;
  @JsonKey(name: 'hero_appearance')
  final String? heroAppearance;
  @JsonKey(name: 'relationship_description')
  final String? relationshipDescription;
  final int? rating;
  @JsonKey(name: 'audio_file_url')
  final String? audioFileUrl;
  @JsonKey(name: 'audio_provider')
  final String? audioProvider;
  @JsonKey(name: 'audio_generation_metadata')
  final Map<String, dynamic>? audioGenerationMetadata;
  final String status;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'generation_id')
  final String generationId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Story({
    this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.language,
    this.childId,
    this.childName,
    this.childAge,
    this.childGender,
    this.childInterests,
    this.heroId,
    this.heroName,
    this.heroGender,
    this.heroAppearance,
    this.relationshipDescription,
    this.rating,
    this.audioFileUrl,
    this.audioProvider,
    this.audioGenerationMetadata,
    required this.status,
    this.userId,
    required this.generationId,
    this.createdAt,
    this.updatedAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoryToJson(this);

  Language get languageEnum => Language.fromCode(language);
  Gender? get childGenderEnum =>
      childGender != null ? Gender.fromString(childGender!) : null;
  Gender? get heroGenderEnum =>
      heroGender != null ? Gender.fromString(heroGender!) : null;
}

