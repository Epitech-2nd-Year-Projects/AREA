import '../entities/area.dart';
import '../repositories/area_repository.dart';

class CreateArea {
  final AreaRepository repository;
  CreateArea(this.repository);

  Future<Area> call(Area area) async {
    return await repository.createArea(area);
  }
}
