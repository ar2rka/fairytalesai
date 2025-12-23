import 'package:json_annotation/json_annotation.dart';
import '../value_objects/language.dart';

part 'free_story.g.dart';

@JsonSerializable()
class FreeStory {
  final String id;
  final String title;
  final String content;
  @JsonKey(name: 'age_category')
  final String ageCategory; // '2-3', '3-5', '5-7'
  final String language; // 'en', 'ru'
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  FreeStory({
    required this.id,
    required this.title,
    required this.content,
    required this.ageCategory,
    required this.language,
    required this.isActive,
    required this.createdAt,
  });

  factory FreeStory.fromJson(Map<String, dynamic> json) =>
      _$FreeStoryFromJson(json);

  Map<String, dynamic> toJson() => _$FreeStoryToJson(this);

  Language get languageEnum => Language.fromCode(language);

  // Маппинг age_category из БД ('2-3', '3-5', '5-7') в отображаемые значения
  String get ageCategoryDisplay {
    switch (ageCategory) {
      case '2-3':
        return '2-3';
      case '3-5':
        return '3-5';
      case '5-7':
        return '5-7';
      default:
        return ageCategory;
    }
  }
}

