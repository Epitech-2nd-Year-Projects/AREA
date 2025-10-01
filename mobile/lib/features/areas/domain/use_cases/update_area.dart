import 'package:area/features/areas/domain/entities/area.dart';

import '../repositories/area_repository.dart';

class UpdateArea {
  final AreaRepository _repository;

  UpdateArea(this._repository);

  Future<Area> call(Area area) async {
    return _repository.updateArea(area);
  }
}
