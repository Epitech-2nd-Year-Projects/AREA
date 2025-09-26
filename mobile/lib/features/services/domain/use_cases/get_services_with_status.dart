import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_with_status.dart';
import '../repositories/services_repository.dart';
import '../value_objects/service_category.dart';

class GetServicesWithStatus {
  final ServicesRepository repository;

  GetServicesWithStatus(this.repository);

  Future<Either<Failure, List<ServiceWithStatus>>>
    call(ServiceCategory? category) async {
      return await repository.getServicesWithStatus(category: category);
  }
}