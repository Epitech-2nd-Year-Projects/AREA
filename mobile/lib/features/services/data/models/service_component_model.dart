import '../../domain/entities/service_component.dart';
import '../../domain/value_objects/component_kind.dart';

class ServiceComponentModel {
  final String id;
  final String providerId;
  final ComponentKind kind;
  final String name;
  final String displayName;
  final String description;
  final int version;
  final Map<String, dynamic> inputSchema;
  final Map<String, dynamic> outputSchema;
  final Map<String, dynamic> metadata;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceComponentModel({
    required this.id,
    required this.providerId,
    required this.kind,
    required this.name,
    required this.displayName,
    required this.description,
    required this.version,
    required this.inputSchema,
    required this.outputSchema,
    required this.metadata,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from about.json action/reaction
  factory ServiceComponentModel.fromAboutComponent({
    required String providerId,
    required ComponentKind kind,
    required String name,
    required String description,
  }) {
    final now = DateTime.now();

    return ServiceComponentModel(
      id: '${providerId}_${kind.value}_${name}',
      providerId: providerId,
      kind: kind,
      name: name,
      displayName: _formatDisplayName(name),
      description: description,
      version: 1,
      inputSchema: {},
      outputSchema: {},
      metadata: {},
      isEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _formatDisplayName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  ServiceComponent toEntity() {
    return ServiceComponent(
      id: id,
      providerId: providerId,
      kind: kind,
      name: name,
      displayName: displayName,
      description: description,
      version: version,
      inputSchema: inputSchema,
      outputSchema: outputSchema,
      metadata: metadata,
      isEnabled: isEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}