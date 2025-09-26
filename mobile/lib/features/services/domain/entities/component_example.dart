import 'package:equatable/equatable.dart';

class ComponentExample extends Equatable {
  final String id;
  final String componentId;
  final Map<String, dynamic> exampleInput;
  final Map<String, dynamic> exampleOutput;

  const ComponentExample({
    required this.id,
    required this.componentId,
    required this.exampleInput,
    required this.exampleOutput,
  });

  @override
  List<Object?> get props => [
    id,
    componentId,
    exampleInput,
    exampleOutput,
  ];
}