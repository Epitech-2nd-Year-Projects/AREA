import 'package:equatable/equatable.dart';
import 'user_service_subscription.dart';

enum ServiceSubscriptionStatus {
  authorizationRequired,
  subscribed,
}

class ServiceAuthorizationData extends Equatable {
  final String authorizationUrl;
  final String? state;
  final String? codeVerifier;
  final String? codeChallenge;
  final String? codeChallengeMethod;

  const ServiceAuthorizationData({
    required this.authorizationUrl,
    this.state,
    this.codeVerifier,
    this.codeChallenge,
    this.codeChallengeMethod,
  });

  @override
  List<Object?> get props => [
        authorizationUrl,
        state,
        codeVerifier,
        codeChallenge,
        codeChallengeMethod,
      ];
}

class ServiceSubscriptionResult extends Equatable {
  final ServiceSubscriptionStatus status;
  final ServiceAuthorizationData? authorization;
  final UserServiceSubscription? subscription;

  const ServiceSubscriptionResult({
    required this.status,
    this.authorization,
    this.subscription,
  });

  bool get requiresAuthorization =>
      status == ServiceSubscriptionStatus.authorizationRequired;

  @override
  List<Object?> get props => [status, authorization, subscription];
}
