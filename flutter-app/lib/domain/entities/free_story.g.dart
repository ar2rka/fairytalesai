// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'free_story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreeStory _$FreeStoryFromJson(Map<String, dynamic> json) => FreeStory(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      ageCategory: json['age_category'] as String,
      language: json['language'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FreeStoryToJson(FreeStory instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'age_category': instance.ageCategory,
      'language': instance.language,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };
