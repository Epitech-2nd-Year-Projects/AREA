import 'package:equatable/equatable.dart';
import '../../../domain/value_objects/component_kind.dart';

abstract class ServiceDetailsEvent extends Equatable {
  const ServiceDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadServiceDetails extends ServiceDetailsEvent {
  final String serviceId;

  const LoadServiceDetails(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class LoadServiceComponents extends ServiceDetailsEvent {
  final String serviceId;

  const LoadServiceComponents(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class FilterComponents extends ServiceDetailsEvent {
  final ComponentKind? kind;

  const FilterComponents(this.kind);

  @override
  List<Object?> get props => [kind];
}

class SearchComponents extends ServiceDetailsEvent {
  final String query;

  const SearchComponents(this.query);

  @override
  List<Object?> get props => [query];
}
