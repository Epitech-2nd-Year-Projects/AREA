import 'package:meta/meta.dart';
import '../../domain/entities/service_subscription_result.dart';
import 'user_service_subscription_model.dart';

class SubscribeServiceResponseModel {
  final ServiceSubscriptionStatus status;
  final ServiceAuthorizationDataModel? authorization;
  final UserServiceSubscriptionModel? subscription;

  const SubscribeServiceResponseModel({
    required this.status,
    this.authorization,
    this.subscription,
  });

  factory SubscribeServiceResponseModel.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'] as String;
    final status = statusValue == 'authorization_required'
        ? ServiceSubscriptionStatus.authorizationRequired
        : ServiceSubscriptionStatus.subscribed;

    ServiceAuthorizationDataModel? authorization;
    if (json['authorization'] is Map<String, dynamic>) {
      authorization = ServiceAuthorizationDataModel.fromJson(
        json['authorization'] as Map<String, dynamic>,
      );
    }

    UserServiceSubscriptionModel? subscription;
    if (json['subscription'] is Map<String, dynamic>) {
      subscription = UserServiceSubscriptionModel.fromJson(
        json['subscription'] as Map<String, dynamic>,
      );
    }

    return SubscribeServiceResponseModel(
      status: status,
      authorization: authorization,
      subscription: subscription,
    );
  }

  ServiceSubscriptionResult toEntity() {
    return ServiceSubscriptionResult(
      status: status,
      authorization: authorization?.toEntity(),
      subscription: subscription?.toEntity(),
    );
  }
}

@immutable
class ServiceAuthorizationDataModel {
  final String authorizationUrl;
  final String? state;
  final String? codeVerifier;
  final String? codeChallenge;
  final String? codeChallengeMethod;

  const ServiceAuthorizationDataModel({
    required this.authorizationUrl,
    this.state,
    this.codeVerifier,
    this.codeChallenge,
    this.codeChallengeMethod,
  });

  factory ServiceAuthorizationDataModel.fromJson(Map<String, dynamic> json) {
    final url = json['authorizationUrl'] ?? json['authorization_url'];
    if (url is! String) {
      throw Exception('Invalid subscription authorization payload');
    }

    return ServiceAuthorizationDataModel(
      authorizationUrl: url,
      state: json['state'] as String?,
      codeVerifier: (json['codeVerifier'] ?? json['code_verifier']) as String?,
      codeChallenge:
          (json['codeChallenge'] ?? json['code_challenge']) as String?,
      codeChallengeMethod: (json['codeChallengeMethod'] ??
          json['code_challenge_method']) as String?,
    );
  }

  ServiceAuthorizationData toEntity() {
    return ServiceAuthorizationData(
      authorizationUrl: authorizationUrl,
      state: state,
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      codeChallengeMethod: codeChallengeMethod,
    );
  }
}
