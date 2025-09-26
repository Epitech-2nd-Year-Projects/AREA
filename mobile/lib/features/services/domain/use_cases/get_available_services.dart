import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_provider.dart';
import '../repositories/services_repository.dart';
import '../value_objects/service_category.dart';

class GetAvailableServices {
  final ServicesRepository repository;

  GetAvailableServices(this.repository);

  Future<Either<Failure, List<ServiceProvider>>> call({
    ServiceCategory? category,
  }) async {
    return await repository.getAvailableServices(category: category);
  }
}