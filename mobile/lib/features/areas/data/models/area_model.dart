import '../models/area_component_model.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/area_status.dart';

class AreaModel {
  final String id;
  final String name;
  final String? description;
  final AreaStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AreaComponentModel action;
  final List<AreaComponentModel> reactions;

  AreaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.action,
    required this.reactions,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: AreaStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      action: AreaComponentModel.fromJson(
        json['action'] as Map<String, dynamic>,
      ),
      reactions: (json['reactions'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AreaComponentModel.fromJson)
          .toList(),
    );
  }

  Area toEntity() {
    return Area(
      id: id,
      name: name,
      description: description,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      action: action.toEntity(),
      reactions: reactions.map((r) => r.toEntity()).toList(),
    );
  }
}
