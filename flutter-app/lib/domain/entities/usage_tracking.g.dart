// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageTracking _$UsageTrackingFromJson(Map<String, dynamic> json) =>
    UsageTracking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      actionTimestamp: DateTime.parse(json['action_timestamp'] as String),
      resourceId: json['resource_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UsageTrackingToJson(UsageTracking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'action_type': instance.actionType,
      'action_timestamp': instance.actionTimestamp.toIso8601String(),
      'resource_id': instance.resourceId,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
    };
