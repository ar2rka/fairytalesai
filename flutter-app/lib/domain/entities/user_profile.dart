import 'package:json_annotation/json_annotation.dart';
import '../value_objects/subscription_plan.dart';
import '../value_objects/subscription_status.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String name;
  @JsonKey(name: 'subscription_plan')
  final String subscriptionPlan;
  @JsonKey(name: 'subscription_status')
  final String subscriptionStatus;
  @JsonKey(name: 'subscription_start_date')
  final DateTime subscriptionStartDate;
  @JsonKey(name: 'subscription_end_date')
  final DateTime? subscriptionEndDate;
  @JsonKey(name: 'monthly_story_count')
  final int monthlyStoryCount;
  @JsonKey(name: 'last_reset_date')
  final DateTime lastResetDate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.monthlyStoryCount,
    required this.lastResetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  SubscriptionPlan get plan => SubscriptionPlan.fromString(subscriptionPlan);
  SubscriptionStatus get status =>
      SubscriptionStatus.fromString(subscriptionStatus);
}

