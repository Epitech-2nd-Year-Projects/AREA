import 'package:equatable/equatable.dart';

class AreaTemplateStep extends Equatable {
  final String providerId;
  final String providerDisplayName;
  final String componentName;
  final String componentDisplayName;
  final Map<String, dynamic> defaultParams;

  const AreaTemplateStep({
    required this.providerId,
    required this.providerDisplayName,
    required this.componentName,
    required this.componentDisplayName,
    required this.defaultParams,
  });

  @override
  List<Object?> get props => [
        providerId,
        providerDisplayName,
        componentName,
        componentDisplayName,
        defaultParams,
      ];
}

class AreaTemplate extends Equatable {
  final String suggestedName;
  final String? suggestedDescription;
  final AreaTemplateStep action;
  final AreaTemplateStep reaction;

  const AreaTemplate({
    required this.suggestedName,
    this.suggestedDescription,
    required this.action,
    required this.reaction,
  });

  @override
  List<Object?> get props => [
        suggestedName,
        suggestedDescription,
        action,
        reaction,
      ];
}
