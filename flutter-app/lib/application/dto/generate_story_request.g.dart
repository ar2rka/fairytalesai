// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_story_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateStoryRequest _$GenerateStoryRequestFromJson(
        Map<String, dynamic> json) =>
    GenerateStoryRequest(
      storyType: json['story_type'] as String,
      childId: json['child_id'] as String?,
      heroId: json['hero_id'] as String?,
      storyLength: (json['story_length'] as num?)?.toInt(),
      heroAppearance: json['hero_appearance'] as String?,
      relationshipDescription: json['relationship_description'] as String?,
      moral: json['moral'] as String,
      language: json['language'] as String,
    );

Map<String, dynamic> _$GenerateStoryRequestToJson(
        GenerateStoryRequest instance) =>
    <String, dynamic>{
      'story_type': instance.storyType,
      'child_id': instance.childId,
      'hero_id': instance.heroId,
      'story_length': instance.storyLength,
      'hero_appearance': instance.heroAppearance,
      'relationship_description': instance.relationshipDescription,
      'moral': instance.moral,
      'language': instance.language,
    };
