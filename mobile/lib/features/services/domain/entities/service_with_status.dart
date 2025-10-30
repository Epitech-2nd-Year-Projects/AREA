import 'package:equatable/equatable.dart';
import 'service_provider.dart';
import 'user_service_subscription.dart';

class ServiceWithStatus extends Equatable {
  final ServiceProvider provider;
  final bool isSubscribed;
  final UserServiceSubscription? subscription;

  const ServiceWithStatus({
    required this.provider,
    required this.isSubscribed,
    this.subscription,
  });

  @override
  List<Object?> get props => [provider, isSubscribed, subscription];
}
