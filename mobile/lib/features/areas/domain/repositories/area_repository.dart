import '../entities/area.dart';
import '../entities/area_draft.dart';
import '../entities/area_history_entry.dart';
import '../entities/area_status.dart';

abstract class AreaRepository {
  Future<List<Area>> getAreas();
  Future<Area> createArea(AreaDraft draft);
  Future<Area> updateArea(Area initial, AreaDraft draft);
  Future<Area> updateAreaStatus(String areaId, AreaStatus status);
  Future<List<AreaHistoryEntry>> getAreaHistory(
    String areaId, {
    int limit = 5,
  });
  Future<void> deleteArea(String areaId);
  Future<void> executeArea(String areaId);
}
