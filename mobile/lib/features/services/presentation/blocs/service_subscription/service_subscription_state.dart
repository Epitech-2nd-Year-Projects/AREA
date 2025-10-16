import 'package:equatable/equatable.dart';
import '../../../domain/entities/service_subscription_result.dart';
import '../../../domain/entities/user_service_subscription.dart';

abstract class ServiceSubscriptionState extends Equatable {
  const ServiceSubscriptionState();

  @override
  List<Object?> get props => [];
}

class ServiceSubscriptionInitial extends ServiceSubscriptionState {}

class ServiceSubscriptionLoading extends ServiceSubscriptionState {}

class ServiceSubscriptionAwaitingAuthorization extends ServiceSubscriptionState {
  final ServiceAuthorizationData authorization;

  const ServiceSubscriptionAwaitingAuthorization(this.authorization);

  String get authorizationUrl => authorization.authorizationUrl;

  @override
  List<Object?> get props => [authorization];
}

class ServiceSubscriptionSuccess extends ServiceSubscriptionState {
  final UserServiceSubscription? subscription;

  const ServiceSubscriptionSuccess(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class ServiceUnsubscribed extends ServiceSubscriptionState {}

class ServiceSubscriptionError extends ServiceSubscriptionState {
  final String message;

  const ServiceSubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
