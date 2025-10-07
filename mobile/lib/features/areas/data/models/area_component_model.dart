import '../../../services/data/models/service_component_model.dart';
import '../../domain/entities/area_component_binding.dart';

class AreaComponentModel {
  final String configId;
  final String componentId;
  final String? name;
  final Map<String, dynamic> params;
  final ServiceComponentModel component;

  AreaComponentModel({
    required this.configId,
    required this.componentId,
    required this.name,
    required this.params,
    required this.component,
  });

  factory AreaComponentModel.fromJson(Map<String, dynamic> json) {
    final params = json['params'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['params'] as Map)
        : <String, dynamic>{};

    return AreaComponentModel(
      configId: json['configId'] as String,
      componentId: json['componentId'] as String,
      name: json['name'] as String?,
      params: params,
      component: ServiceComponentModel.fromJson(
        json['component'] as Map<String, dynamic>,
      ),
    );
  }

  AreaComponentBinding toEntity() {
    return AreaComponentBinding(
      configId: configId,
      componentId: componentId,
      name: name,
      params: params,
      component: component.toEntity(),
    );
  }
}
