import 'package:equatable/equatable.dart';
import '../../../domain/entities/service_with_status.dart';
import '../../../domain/value_objects/service_category.dart';

abstract class ServicesListState extends Equatable {
  const ServicesListState();

  @override
  List<Object?> get props => [];
}

class ServicesListInitial extends ServicesListState {}

class ServicesListLoading extends ServicesListState {}

class ServicesListLoaded extends ServicesListState {
  final List<ServiceWithStatus> services;
  final List<ServiceWithStatus> filteredServices;
  final ServiceCategory? selectedCategory;
  final String searchQuery;

  const ServicesListLoaded({
    required this.services,
    required this.filteredServices,
    this.selectedCategory,
    required this.searchQuery,
  });

  ServicesListLoaded copyWith({
    List<ServiceWithStatus>? services,
    List<ServiceWithStatus>? filteredServices,
    ServiceCategory? selectedCategory,
    bool clearCategory = false, // Nouveau paramètre pour forcer null
    String? searchQuery,
  }) {
    return ServicesListLoaded(
      services: services ?? this.services,
      filteredServices: filteredServices ?? this.filteredServices,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    services,
    filteredServices,
    selectedCategory,
    searchQuery,
  ];
}

class ServicesListError extends ServicesListState {
  final String message;

  const ServicesListError(this.message);

  @override
  List<Object?> get props => [message];
}