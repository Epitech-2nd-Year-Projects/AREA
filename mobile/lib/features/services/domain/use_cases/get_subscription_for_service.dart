import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_service_subscription.dart';
import '../repositories/services_repository.dart';

class GetSubscriptionForService {
  final ServicesRepository repository;

  GetSubscriptionForService(this.repository);

  Future<Either<Failure, UserServiceSubscription?>> call(
    String serviceId,
  ) async {
    return await repository.getSubscriptionForService(serviceId);
  }
}
