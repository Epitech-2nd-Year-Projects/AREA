import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/about_info.dart';
import '../repositories/services_repository.dart';

class GetAboutInfoUseCase {
  final ServicesRepository repository;

  GetAboutInfoUseCase(this.repository);

  Future<Either<Failure, AboutInfo>> call() async {
    return await repository.getAboutInfo();
  }
}
