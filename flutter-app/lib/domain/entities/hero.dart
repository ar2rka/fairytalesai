import 'package:json_annotation/json_annotation.dart';
import '../value_objects/gender.dart';
import '../value_objects/language.dart';

part 'hero.g.dart';

@JsonSerializable()
class Hero {
  final String? id;
  final String name;
  final String gender;
  final String appearance;
  @JsonKey(name: 'personality_traits')
  final List<String> personalityTraits;
  final List<String> interests;
  final List<String> strengths;
  final String language;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Hero({
    this.id,
    required this.name,
    required this.gender,
    required this.appearance,
    required this.personalityTraits,
    required this.interests,
    required this.strengths,
    required this.language,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Hero.fromJson(Map<String, dynamic> json) => _$HeroFromJson(json);

  Map<String, dynamic> toJson() => _$HeroToJson(this);

  Gender get genderEnum => Gender.fromString(gender);
  Language get languageEnum => Language.fromCode(language);
}

