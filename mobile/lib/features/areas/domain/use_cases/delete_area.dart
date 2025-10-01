import '../repositories/area_repository.dart';

class DeleteArea {
  final AreaRepository _repository;

  DeleteArea(this._repository);

  Future<void> call(String areaId) async {
    return _repository.deleteArea(areaId);
  }
}
