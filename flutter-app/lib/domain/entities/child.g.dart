// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Child _$ChildFromJson(Map<String, dynamic> json) => Child(
      id: json['id'] as String?,
      name: json['name'] as String,
      ageCategory: json['age_category'] as String,
      gender: json['gender'] as String,
      interests:
          (json['interests'] as List<dynamic>).map((e) => e as String).toList(),
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ChildToJson(Child instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'age_category': instance.ageCategory,
      'gender': instance.gender,
      'interests': instance.interests,
      'user_id': instance.userId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
