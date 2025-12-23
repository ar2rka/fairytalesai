import 'package:json_annotation/json_annotation.dart';

part 'usage_tracking.g.dart';

@JsonSerializable()
class UsageTracking {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'action_type')
  final String actionType;
  @JsonKey(name: 'action_timestamp')
  final DateTime actionTimestamp;
  @JsonKey(name: 'resource_id')
  final String? resourceId;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  UsageTracking({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.actionTimestamp,
    this.resourceId,
    this.metadata,
    required this.createdAt,
  });

  factory UsageTracking.fromJson(Map<String, dynamic> json) =>
      _$UsageTrackingFromJson(json);
}

