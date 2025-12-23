// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      subscriptionPlan: json['subscription_plan'] as String,
      subscriptionStatus: json['subscription_status'] as String,
      subscriptionStartDate:
          DateTime.parse(json['subscription_start_date'] as String),
      subscriptionEndDate: json['subscription_end_date'] == null
          ? null
          : DateTime.parse(json['subscription_end_date'] as String),
      monthlyStoryCount: (json['monthly_story_count'] as num).toInt(),
      lastResetDate: DateTime.parse(json['last_reset_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subscription_plan': instance.subscriptionPlan,
      'subscription_status': instance.subscriptionStatus,
      'subscription_start_date':
          instance.subscriptionStartDate.toIso8601String(),
      'subscription_end_date': instance.subscriptionEndDate?.toIso8601String(),
      'monthly_story_count': instance.monthlyStoryCount,
      'last_reset_date': instance.lastResetDate.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
