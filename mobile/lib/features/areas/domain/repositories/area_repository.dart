import '../entities/area.dart';
import '../entities/area_draft.dart';

abstract class AreaRepository {
  Future<List<Area>> getAreas();
  Future<Area> createArea(AreaDraft draft);
  Future<Area> updateArea(String areaId, AreaDraft draft);
  Future<void> deleteArea(String areaId);
  Future<void> executeArea(String areaId);
}
