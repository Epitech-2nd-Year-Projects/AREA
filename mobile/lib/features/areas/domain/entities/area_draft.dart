import 'package:equatable/equatable.dart';

class AreaDraft extends Equatable {
  final String name;
  final String? description;
  final AreaComponentDraft action;
  final List<AreaComponentDraft> reactions;

  const AreaDraft({
    required this.name,
    required this.description,
    required this.action,
    required this.reactions,
  });

  @override
  List<Object?> get props => [name, description, action, reactions];
}

class AreaComponentDraft extends Equatable {
  final String componentId;
  final String? name;
  final Map<String, dynamic> params;

  const AreaComponentDraft({
    required this.componentId,
    required this.name,
    required this.params,
  });

  AreaComponentDraft copyWith({
    String? componentId,
    String? name,
    Map<String, dynamic>? params,
  }) {
    return AreaComponentDraft(
      componentId: componentId ?? this.componentId,
      name: name ?? this.name,
      params: params ?? this.params,
    );
  }

  @override
  List<Object?> get props => [componentId, name, params];
}
