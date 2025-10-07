import 'package:equatable/equatable.dart';
import '../value_objects/component_kind.dart';
import 'service_provider_summary.dart';
import 'component_parameter.dart';

class ServiceComponent extends Equatable {
  final String id;
  final ComponentKind kind;
  final String name;
  final String displayName;
  final String? description;
  final ServiceProviderSummary provider;
  final Map<String, dynamic> metadata;
  final List<ComponentParameter> parameters;

  const ServiceComponent({
    required this.id,
    required this.kind,
    required this.name,
    required this.displayName,
    required this.description,
    required this.provider,
    required this.metadata,
    required this.parameters,
  });

  bool get isAction => kind == ComponentKind.action;
  bool get isReaction => kind == ComponentKind.reaction;
  bool get hasConfigurableParams => parameters.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        kind,
        name,
        displayName,
        description,
        provider,
        metadata,
        parameters,
      ];
}
