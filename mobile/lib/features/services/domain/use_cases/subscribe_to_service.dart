import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_service_subscription.dart';
import '../repositories/services_repository.dart';

class SubscribeToService {
  final ServicesRepository repository;

  SubscribeToService(this.repository);

  Future<Either<Failure, UserServiceSubscription>> call({
    required String serviceId,
    required List<String> requestedScopes,
  }) async {
    return await repository.subscribeToService(
      serviceId: serviceId,
      requestedScopes: requestedScopes,
    );
  }
}