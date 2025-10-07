import '../../domain/entities/service_subscription_exchange_result.dart';
import 'identity_summary_model.dart';
import 'user_service_subscription_model.dart';

class SubscribeExchangeResponseModel {
  final UserServiceSubscriptionModel subscription;
  final IdentitySummaryModel? identity;

  const SubscribeExchangeResponseModel({
    required this.subscription,
    this.identity,
  });

  factory SubscribeExchangeResponseModel.fromJson(Map<String, dynamic> json) {
    final subscriptionJson = json['subscription'];
    if (subscriptionJson is! Map<String, dynamic>) {
      throw Exception('Invalid subscription exchange response');
    }

    IdentitySummaryModel? identity;
    final identityJson = json['identity'];
    if (identityJson is Map<String, dynamic>) {
      identity = IdentitySummaryModel.fromJson(identityJson);
    }

    return SubscribeExchangeResponseModel(
      subscription: UserServiceSubscriptionModel.fromJson(subscriptionJson),
      identity: identity,
    );
  }

  ServiceSubscriptionExchangeResult toEntity() {
    return ServiceSubscriptionExchangeResult(
      subscription: subscription.toEntity(),
      identity: identity?.toEntity(),
    );
  }
}
