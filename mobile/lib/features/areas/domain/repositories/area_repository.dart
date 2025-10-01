import '../entities/area.dart';

abstract class AreaRepository {
  Future<List<Area>> getAreas();
  Future<Area> createArea(Area area);
  Future<Area> updateArea(Area area);
  Future<void> deleteArea(String areaId);
}
