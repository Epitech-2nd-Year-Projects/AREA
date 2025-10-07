import '../../domain/entities/area.dart';
import '../../domain/entities/area_draft.dart';
import '../../domain/repositories/area_repository.dart';
import '../datasources/area_remote_datasource.dart';
import '../models/area_model.dart';
import '../models/area_request_model.dart';

class AreaRepositoryImpl implements AreaRepository {
  final AreaRemoteDataSource _remote;

  AreaRepositoryImpl(this._remote);

  @override
  Future<List<Area>> getAreas() async {
    final models = await _remote.listAreas();
    return models.map((AreaModel model) => model.toEntity()).toList();
  }

  @override
  Future<Area> createArea(AreaDraft draft) async {
    final request = AreaRequestModel.fromDraft(draft);
    final model = await _remote.createArea(request);
    return model.toEntity();
  }

  @override
  Future<Area> updateArea(String areaId, AreaDraft draft) async {
    final request = AreaRequestModel.fromDraft(draft);
    final model = await _remote.updateArea(areaId, request);
    return model.toEntity();
  }

  @override
  Future<void> deleteArea(String areaId) {
    return _remote.deleteArea(areaId);
  }

  @override
  Future<void> executeArea(String areaId) {
    return _remote.executeArea(areaId);
  }
}
