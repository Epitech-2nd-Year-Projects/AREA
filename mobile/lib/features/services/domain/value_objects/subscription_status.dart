enum SubscriptionStatus {
  active('active'),
  revoked('revoked'),
  expired('expired'),
  needsConsent('needs_consent');

  const SubscriptionStatus(this.value);
  final String value;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
          (status) => status.value == value,
      orElse: () => SubscriptionStatus.needsConsent,
    );
  }

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.revoked:
        return 'Revoked';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.needsConsent:
        return 'Needs Consent';
    }
  }

  bool get isUsable => this == SubscriptionStatus.active;
}