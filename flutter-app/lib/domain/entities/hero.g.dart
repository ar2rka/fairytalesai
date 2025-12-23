// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hero.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hero _$HeroFromJson(Map<String, dynamic> json) => Hero(
      id: json['id'] as String?,
      name: json['name'] as String,
      gender: json['gender'] as String,
      appearance: json['appearance'] as String,
      personalityTraits: (json['personality_traits'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      interests:
          (json['interests'] as List<dynamic>).map((e) => e as String).toList(),
      strengths:
          (json['strengths'] as List<dynamic>).map((e) => e as String).toList(),
      language: json['language'] as String,
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$HeroToJson(Hero instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gender': instance.gender,
      'appearance': instance.appearance,
      'personality_traits': instance.personalityTraits,
      'interests': instance.interests,
      'strengths': instance.strengths,
      'language': instance.language,
      'user_id': instance.userId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
