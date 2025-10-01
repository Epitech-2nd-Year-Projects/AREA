import '../entities/area.dart';

abstract class AreaRepository {
  Future<List<Area>> getAreas();            // Récupérer la liste des Areas de l’utilisateur
  Future<Area> createArea(Area area);       // Créer une nouvelle Area
  Future<Area> updateArea(Area area);       // Mettre à jour une Area (ex. renommer, activer/désactiver)
  Future<void> deleteArea(String areaId);   // Supprimer une Area par son id
}
