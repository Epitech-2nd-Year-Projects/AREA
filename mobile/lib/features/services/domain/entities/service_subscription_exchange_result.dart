import 'package:equatable/equatable.dart';
import 'service_identity_summary.dart';
import 'user_service_subscription.dart';

class ServiceSubscriptionExchangeResult extends Equatable {
  final UserServiceSubscription subscription;
  final ServiceIdentitySummary? identity;

  const ServiceSubscriptionExchangeResult({
    required this.subscription,
    this.identity,
  });

  @override
  List<Object?> get props => [subscription, identity];
}
