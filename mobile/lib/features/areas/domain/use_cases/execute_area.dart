import '../repositories/area_repository.dart';

class ExecuteArea {
  final AreaRepository _repository;

  ExecuteArea(this._repository);

  Future<void> call(String areaId) {
    return _repository.executeArea(areaId);
  }
}
