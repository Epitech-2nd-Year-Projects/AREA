import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/service_component.dart';
import '../repositories/services_repository.dart';
import '../value_objects/component_kind.dart';

class GetServiceComponents {
  final ServicesRepository repository;

  GetServiceComponents(this.repository);

  Future<Either<Failure, List<ServiceComponent>>> call(
    String serviceId, {
    ComponentKind? kind,
    bool onlySubscribed = false,
  }) async {
    return repository.getServiceComponents(
      serviceId,
      kind: kind,
      onlySubscribed: onlySubscribed,
    );
  }
}
