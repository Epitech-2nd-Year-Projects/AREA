import 'package:equatable/equatable.dart';
import '../../../domain/value_objects/service_category.dart';

abstract class ServicesListEvent extends Equatable {
  const ServicesListEvent();

  @override
  List<Object?> get props => [];
}

class LoadServices extends ServicesListEvent {
  final ServiceCategory? category;

  const LoadServices([this.category]);

  @override
  List<Object?> get props => [category];
}

class RefreshServices extends ServicesListEvent {}

class FilterByCategory extends ServicesListEvent {
  final ServiceCategory? category;

  const FilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchServices extends ServicesListEvent {
  final String query;

  const SearchServices(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearFilters extends ServicesListEvent {}