import '../../domain/entities/component_parameter.dart';
import '../../domain/entities/service_component.dart';
import '../../domain/entities/service_provider_summary.dart';
import '../../domain/value_objects/component_kind.dart';

class ServiceComponentModel {
  final String id;
  final ComponentKind kind;
  final String name;
  final String displayName;
  final String? description;
  final Map<String, dynamic> metadata;
  final ServiceProviderSummaryModel provider;
  final List<ComponentParameterModel> parameters;

  ServiceComponentModel({
    required this.id,
    required this.kind,
    required this.name,
    required this.displayName,
    required this.description,
    required this.metadata,
    required this.provider,
    required this.parameters,
  });

  factory ServiceComponentModel.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata'] as Map<String, dynamic>?) ?? const {};
    final parameters = <ComponentParameterModel>[];
    final rawParams = metadata['parameters'];
    if (rawParams is List) {
      for (final item in rawParams) {
        if (item is Map<String, dynamic>) {
          parameters.add(ComponentParameterModel.fromJson(item));
        }
      }
    }

    return ServiceComponentModel(
      id: json['id'] as String,
      kind: ComponentKind.fromString(json['kind'] as String),
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      metadata: metadata,
      provider: ServiceProviderSummaryModel.fromJson(
        json['provider'] as Map<String, dynamic>,
      ),
      parameters: parameters,
    );
  }

  // Backwards compatibility builder for about.json mock data
  factory ServiceComponentModel.fromAboutComponent({
    required String providerId,
    required ComponentKind kind,
    required String name,
    required String description,
  }) {
    return ServiceComponentModel(
      id: '${providerId}_${kind.value}_$name',
      kind: kind,
      name: name,
      displayName: _formatDisplayName(name),
      description: description,
      metadata: const {},
      provider: ServiceProviderSummaryModel(
        id: providerId,
        name: providerId,
        displayName: _formatDisplayName(providerId),
      ),
      parameters: const [],
    );
  }

  static String _formatDisplayName(String value) {
    return value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  ServiceComponent toEntity() {
    return ServiceComponent(
      id: id,
      kind: kind,
      name: name,
      displayName: displayName,
      description: description,
      provider: provider.toEntity(),
      metadata: metadata,
      parameters: parameters.map((p) => p.toEntity()).toList(),
    );
  }
}

class ServiceProviderSummaryModel {
  final String id;
  final String name;
  final String displayName;

  const ServiceProviderSummaryModel({
    required this.id,
    required this.name,
    required this.displayName,
  });

  factory ServiceProviderSummaryModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
    );
  }

  ServiceProviderSummary toEntity() {
    return ServiceProviderSummary(id: id, name: name, displayName: displayName);
  }
}

class ComponentParameterModel {
  final String key;
  final String label;
  final String type;
  final bool required;
  final String? description;
  final List<ComponentParameterOptionModel> options;
  final Map<String, dynamic> extras;

  ComponentParameterModel({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.description,
    required this.options,
    required this.extras,
  });

  factory ComponentParameterModel.fromJson(Map<String, dynamic> json) {
    final options = <ComponentParameterOptionModel>[];
    final rawOptions = json['options'];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map<String, dynamic>) {
          options.add(ComponentParameterOptionModel.fromJson(item));
        }
      }
    }

    final extras = Map<String, dynamic>.from(json)
      ..removeWhere(
        (key, _) =>
            key == 'key' ||
            key == 'label' ||
            key == 'type' ||
            key == 'required' ||
            key == 'description' ||
            key == 'options',
      );

    return ComponentParameterModel(
      key: json['key'] as String,
      label:
          (json['label'] as String?) ??
          _formatDisplayName(json['key'] as String),
      type: (json['type'] as String?) ?? 'string',
      required: json['required'] == true,
      description: json['description'] as String?,
      options: options,
      extras: extras,
    );
  }

  ComponentParameter toEntity() {
    return ComponentParameter(
      key: key,
      label: label,
      type: type,
      required: required,
      description: description,
      options: options.map((o) => o.toEntity()).toList(),
      extras: extras,
    );
  }

  static String _formatDisplayName(String key) {
    return key
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class ComponentParameterOptionModel {
  final String value;
  final String label;

  const ComponentParameterOptionModel({
    required this.value,
    required this.label,
  });

  factory ComponentParameterOptionModel.fromJson(Map<String, dynamic> json) {
    return ComponentParameterOptionModel(
      value: json['value'] is String
          ? json['value'] as String
          : '${json['value']}',
      label: json['label'] as String? ?? '${json['value']}',
    );
  }

  ComponentParameterOption toEntity() {
    return ComponentParameterOption(value: value, label: label);
  }
}
