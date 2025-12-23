import 'package:json_annotation/json_annotation.dart';
import '../value_objects/subscription_plan.dart';
import '../value_objects/payment_status.dart';

part 'purchase_transaction.g.dart';

@JsonSerializable()
class PurchaseTransaction {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'from_plan')
  final String fromPlan;
  @JsonKey(name: 'to_plan')
  final String toPlan;
  final double amount;
  final String currency;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_provider')
  final String paymentProvider;
  @JsonKey(name: 'transaction_reference')
  final String transactionReference;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  PurchaseTransaction({
    required this.id,
    required this.userId,
    required this.fromPlan,
    required this.toPlan,
    required this.amount,
    required this.currency,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paymentProvider,
    required this.transactionReference,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory PurchaseTransaction.fromJson(Map<String, dynamic> json) =>
      _$PurchaseTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseTransactionToJson(this);

  SubscriptionPlan get fromPlanEnum => SubscriptionPlan.fromString(fromPlan);
  SubscriptionPlan get toPlanEnum => SubscriptionPlan.fromString(toPlan);
  PaymentStatus get paymentStatusEnum =>
      PaymentStatus.fromString(paymentStatus);
}

