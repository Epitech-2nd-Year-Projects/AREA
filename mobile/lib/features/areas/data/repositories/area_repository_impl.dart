import '../../domain/entities/area.dart';
import '../../domain/repositories/area_repository.dart';

class AreaRepositoryImpl implements AreaRepository {
  // Liste simulant la base de données des Areas de l'utilisateur courant
  final List<Area> _areas = [
    Area(
      id: '1',
      userId: 'me',
      name: 'Gmail → OneDrive',
      isActive: true,
      actionName: 'mail_with_attachment',
      reactionName: 'save_to_onedrive',
    ),
    Area(
      id: '2',
      userId: 'me',
      name: 'GitHub Issue → Teams',
      isActive: false,
      actionName: 'issue_created',
      reactionName: 'send_teams_message',
    ),
  ];

  @override
  Future<List<Area>> getAreas() async {
    // Simuler un délai réseau
    await Future.delayed(Duration(milliseconds: 500));
    return _areas;
  }

  @override
  Future<Area> createArea(Area area) async {
    await Future.delayed(Duration(milliseconds: 500));
    // Créer un nouvel objet Area avec un ID généré
    final newArea = Area(
      id: _generateId(), 
      userId: area.userId, 
      name: area.name,
      isActive: area.isActive, 
      actionName: area.actionName, 
      reactionName: area.reactionName);
    _areas.add(newArea);
    return newArea;
  }

  @override
  Future<Area> updateArea(Area area) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _areas.indexWhere((a) => a.id == area.id);
    if (index == -1) throw Exception("Area not found");
    _areas[index] = area;
    return area;
  }

  @override
  Future<void> deleteArea(String areaId) async {
    await Future.delayed(Duration(milliseconds: 300));
    _areas.removeWhere((a) => a.id == areaId);
    return;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
