import 'package:equatable/equatable.dart';
import '../value_objects/component_kind.dart';

class ServiceComponent extends Equatable {
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

  const ServiceComponent({
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

  bool get isAction => kind == ComponentKind.action;
  bool get isReaction => kind == ComponentKind.reaction;

  @override
  List<Object?> get props => [
    id,
    providerId,
    kind,
    name,
    displayName,
    description,
    version,
    inputSchema,
    outputSchema,
    metadata,
    isEnabled,
    createdAt,
    updatedAt,
  ];
}