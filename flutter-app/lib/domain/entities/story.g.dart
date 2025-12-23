// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => Story(
      id: json['id'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      language: json['language'] as String,
      childId: json['child_id'] as String?,
      childName: json['child_name'] as String?,
      childAge: (json['child_age'] as num?)?.toInt(),
      childGender: json['child_gender'] as String?,
      childInterests: (json['child_interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      heroId: json['hero_id'] as String?,
      heroName: json['hero_name'] as String?,
      heroGender: json['hero_gender'] as String?,
      heroAppearance: json['hero_appearance'] as String?,
      relationshipDescription: json['relationship_description'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      audioFileUrl: json['audio_file_url'] as String?,
      audioProvider: json['audio_provider'] as String?,
      audioGenerationMetadata:
          json['audio_generation_metadata'] as Map<String, dynamic>?,
      status: json['status'] as String,
      userId: json['user_id'] as String?,
      generationId: json['generation_id'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'summary': instance.summary,
      'language': instance.language,
      'child_id': instance.childId,
      'child_name': instance.childName,
      'child_age': instance.childAge,
      'child_gender': instance.childGender,
      'child_interests': instance.childInterests,
      'hero_id': instance.heroId,
      'hero_name': instance.heroName,
      'hero_gender': instance.heroGender,
      'hero_appearance': instance.heroAppearance,
      'relationship_description': instance.relationshipDescription,
      'rating': instance.rating,
      'audio_file_url': instance.audioFileUrl,
      'audio_provider': instance.audioProvider,
      'audio_generation_metadata': instance.audioGenerationMetadata,
      'status': instance.status,
      'user_id': instance.userId,
      'generation_id': instance.generationId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
