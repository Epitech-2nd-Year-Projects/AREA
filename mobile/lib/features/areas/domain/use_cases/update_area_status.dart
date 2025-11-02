import '../entities/area.dart';
import '../entities/area_status.dart';
import '../repositories/area_repository.dart';

class UpdateAreaStatus {
  final AreaRepository _repository;

  UpdateAreaStatus(this._repository);

  Future<Area> call({
    required String areaId,
    required AreaStatus status,
  }) {
    return _repository.updateAreaStatus(areaId, status);
  }
}
