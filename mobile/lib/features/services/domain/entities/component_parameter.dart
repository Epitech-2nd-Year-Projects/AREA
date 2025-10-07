import 'package:equatable/equatable.dart';

class ComponentParameter extends Equatable {
  final String key;
  final String label;
  final String type;
  final bool required;
  final String? description;
  final List<ComponentParameterOption> options;
  final Map<String, dynamic> extras;

  const ComponentParameter({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    this.description,
    this.options = const [],
    this.extras = const {},
  });

  bool get hasOptions => options.isNotEmpty;

  @override
  List<Object?> get props => [
        key,
        label,
        type,
        required,
        description,
        options,
        extras,
      ];
}

class ComponentParameterOption extends Equatable {
  final String value;
  final String label;

  const ComponentParameterOption({
    required this.value,
    required this.label,
  });

  @override
  List<Object?> get props => [value, label];
}
