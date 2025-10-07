import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_subscription_result.dart';
import '../repositories/services_repository.dart';

class SubscribeToService {
  final ServicesRepository repository;

  SubscribeToService(this.repository);

  Future<Either<Failure, ServiceSubscriptionResult>> call({
    required String serviceId,
    List<String> requestedScopes = const [],
    String? redirectUri,
    String? state,
    bool? usePkce,
  }) async {
    return await repository.subscribeToService(
      serviceId: serviceId,
      requestedScopes: requestedScopes,
      redirectUri: redirectUri,
      state: state,
      usePkce: usePkce,
    );
  }
}
