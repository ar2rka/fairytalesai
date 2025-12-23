// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Generation _$GenerationFromJson(Map<String, dynamic> json) => Generation(
      generationId: json['generation_id'] as String,
      attemptNumber: (json['attempt_number'] as num).toInt(),
      modelUsed: json['model_used'] as String,
      fullResponse: json['full_response'] as Map<String, dynamic>?,
      status: json['status'] as String,
      prompt: json['prompt'] as String,
      userId: json['user_id'] as String,
      storyType: json['story_type'] as String,
      storyLength: (json['story_length'] as num?)?.toInt(),
      heroAppearance: json['hero_appearance'] as String?,
      relationshipDescription: json['relationship_description'] as String?,
      moral: json['moral'] as String,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$GenerationToJson(Generation instance) =>
    <String, dynamic>{
      'generation_id': instance.generationId,
      'attempt_number': instance.attemptNumber,
      'model_used': instance.modelUsed,
      'full_response': instance.fullResponse,
      'status': instance.status,
      'prompt': instance.prompt,
      'user_id': instance.userId,
      'story_type': instance.storyType,
      'story_length': instance.storyLength,
      'hero_appearance': instance.heroAppearance,
      'relationship_description': instance.relationshipDescription,
      'moral': instance.moral,
      'error_message': instance.errorMessage,
      'created_at': instance.createdAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
    };
