import 'package:equatable/equatable.dart';

class ServiceProviderSummary extends Equatable {
  final String id;
  final String name;
  final String displayName;

  const ServiceProviderSummary({
    required this.id,
    required this.name,
    required this.displayName,
  });

  @override
  List<Object?> get props => [id, name, displayName];
}
