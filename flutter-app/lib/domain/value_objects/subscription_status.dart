enum SubscriptionStatus {
  active('active'),
  inactive('inactive'),
  cancelled('cancelled'),
  expired('expired');

  final String value;
  const SubscriptionStatus(this.value);

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.inactive,
    );
  }
}

