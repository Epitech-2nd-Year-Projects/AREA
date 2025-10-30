import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/component_example.dart';
import '../repositories/services_repository.dart';

class GetComponentExamples {
  final ServicesRepository repository;

  GetComponentExamples(this.repository);

  Future<Either<Failure, List<ComponentExample>>> call(
    String componentId,
  ) async {
    return await repository.getComponentExamples(componentId);
  }
}
