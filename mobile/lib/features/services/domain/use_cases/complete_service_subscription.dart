import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_subscription_exchange_result.dart';
import '../repositories/services_repository.dart';

class CompleteServiceSubscription {
  final ServicesRepository repository;

  CompleteServiceSubscription(this.repository);

  Future<Either<Failure, ServiceSubscriptionExchangeResult>> call({
    required String serviceId,
    required String code,
    String? codeVerifier,
    String? redirectUri,
  }) async {
    return repository.completeServiceSubscription(
      serviceId: serviceId,
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    );
  }
}
