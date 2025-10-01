import '../repositories/area_repository.dart';
import '../entities/area.dart';

class GetAreas {
  final AreaRepository repository;

  GetAreas(this.repository);

  Future<List<Area>> call() async {
    return await repository.getAreas();
  }
}
