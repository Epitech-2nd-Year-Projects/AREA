import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_service_subscription.dart';
import '../repositories/services_repository.dart';

class GetUserSubscriptions {
  final ServicesRepository repository;

  GetUserSubscriptions(this.repository);

  Future<Either<Failure, List<UserServiceSubscription>>> call() async {
    return await repository.getUserSubscriptions();
  }
}