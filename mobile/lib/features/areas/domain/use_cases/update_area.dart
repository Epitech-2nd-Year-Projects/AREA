import '../entities/area.dart';
import '../entities/area_draft.dart';
import '../repositories/area_repository.dart';

class UpdateArea {
  final AreaRepository _repository;

  UpdateArea(this._repository);

  Future<Area> call(String areaId, AreaDraft draft) async {
    return _repository.updateArea(areaId, draft);
  }
}
