import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_provider.dart';
import '../repositories/services_repository.dart';

class GetServiceDetails {
  final ServicesRepository repository;

  GetServiceDetails(this.repository);

  Future<Either<Failure, ServiceProvider>> call(String serviceId) async {
    return await repository.getServiceDetails(serviceId);
  }
}
