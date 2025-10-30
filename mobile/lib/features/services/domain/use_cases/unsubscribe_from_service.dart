import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/services_repository.dart';

class UnsubscribeFromService {
  final ServicesRepository repository;

  UnsubscribeFromService(this.repository);

  Future<Either<Failure, bool>> call(String subscriptionId) async {
    return await repository.unsubscribeFromService(subscriptionId);
  }
}
