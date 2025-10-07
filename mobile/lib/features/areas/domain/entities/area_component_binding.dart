import 'package:equatable/equatable.dart';
import '../../../services/domain/entities/service_component.dart';

class AreaComponentBinding extends Equatable {
  final String configId;
  final String componentId;
  final String? name;
  final Map<String, dynamic> params;
  final ServiceComponent component;

  const AreaComponentBinding({
    required this.configId,
    required this.componentId,
    required this.name,
    required this.params,
    required this.component,
  });

  AreaComponentBinding copyWith({
    String? configId,
    String? componentId,
    String? name,
    Map<String, dynamic>? params,
    ServiceComponent? component,
  }) {
    return AreaComponentBinding(
      configId: configId ?? this.configId,
      componentId: componentId ?? this.componentId,
      name: name ?? this.name,
      params: params ?? this.params,
      component: component ?? this.component,
    );
  }

  @override
  List<Object?> get props => [configId, componentId, name, params, component];
}
