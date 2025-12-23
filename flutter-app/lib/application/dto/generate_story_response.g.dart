// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_story_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateStoryResponse _$GenerateStoryResponseFromJson(
        Map<String, dynamic> json) =>
    GenerateStoryResponse(
      story: Story.fromJson(json['story'] as Map<String, dynamic>),
      generationId: json['generation_id'] as String,
    );

Map<String, dynamic> _$GenerateStoryResponseToJson(
        GenerateStoryResponse instance) =>
    <String, dynamic>{
      'story': instance.story,
      'generation_id': instance.generationId,
    };
