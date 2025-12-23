enum SubscriptionPlan {
  free('free'),
  starter('starter'),
  normal('normal'),
  premium('premium');

  final String value;
  const SubscriptionPlan(this.value);

  static SubscriptionPlan fromString(String value) {
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.value == value,
      orElse: () => SubscriptionPlan.free,
    );
  }

  /// Возвращает длину истории по умолчанию (в минутах) для тарифа
  double get defaultStoryLength {
    switch (this) {
      case SubscriptionPlan.free:
        return 10.0;
      case SubscriptionPlan.starter:
        return 15.0;
      case SubscriptionPlan.normal:
        return 20.0;
      case SubscriptionPlan.premium:
        return 30.0;
    }
  }
}
