// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseTransaction _$PurchaseTransactionFromJson(Map<String, dynamic> json) =>
    PurchaseTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fromPlan: json['from_plan'] as String,
      toPlan: json['to_plan'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      paymentStatus: json['payment_status'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentProvider: json['payment_provider'] as String,
      transactionReference: json['transaction_reference'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PurchaseTransactionToJson(
        PurchaseTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'from_plan': instance.fromPlan,
      'to_plan': instance.toPlan,
      'amount': instance.amount,
      'currency': instance.currency,
      'payment_status': instance.paymentStatus,
      'payment_method': instance.paymentMethod,
      'payment_provider': instance.paymentProvider,
      'transaction_reference': instance.transactionReference,
      'created_at': instance.createdAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'metadata': instance.metadata,
    };
