import '../entities/area.dart';
import '../entities/area_draft.dart';
import '../repositories/area_repository.dart';

class CreateArea {
  final AreaRepository repository;
  CreateArea(this.repository);

  Future<Area> call(AreaDraft draft) async {
    return repository.createArea(draft);
  }
}
