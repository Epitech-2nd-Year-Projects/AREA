import 'package:equatable/equatable.dart';
import 'area_component_binding.dart';
import 'area_status.dart';

class Area extends Equatable {
  final String id;
  final String name;
  final String? description;
  final AreaStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AreaComponentBinding action;
  final List<AreaComponentBinding> reactions;

  const Area({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.action,
    required this.reactions,
  });

  bool get isEnabled => status == AreaStatus.enabled;

  Area copyWith({
    String? id,
    String? name,
    String? description,
    AreaStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    AreaComponentBinding? action,
    List<AreaComponentBinding>? reactions,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      action: action ?? this.action,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    status,
    createdAt,
    updatedAt,
    action,
    reactions,
  ];
}
