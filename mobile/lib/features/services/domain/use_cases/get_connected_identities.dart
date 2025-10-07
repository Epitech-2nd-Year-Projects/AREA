import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/service_identity_summary.dart';
import '../repositories/services_repository.dart';

class GetConnectedIdentities {
  final ServicesRepository repository;

  GetConnectedIdentities(this.repository);

  Future<Either<Failure, List<ServiceIdentitySummary>>> call() {
    return repository.getConnectedIdentities();
  }
}
