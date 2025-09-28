import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/repositories/services_repository.dart';
import '../../../domain/use_cases/get_services_with_status.dart';
import '../../../domain/entities/service_with_status.dart';
import '../../../domain/value_objects/service_category.dart';
import 'services_list_event.dart';
import 'services_list_state.dart';

class ServicesListBloc extends Bloc<ServicesListEvent, ServicesListState> {
  late final GetServicesWithStatus _getServicesWithStatus;

  ServicesListBloc(ServicesRepository repository)
      : super(ServicesListInitial()) {
    _getServicesWithStatus = GetServicesWithStatus(repository);

    on<LoadServices>(_onLoadServices);
    on<RefreshServices>(_onRefreshServices);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchServices>(_onSearchServices);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadServices(
      LoadServices event,
      Emitter<ServicesListState> emit,
      ) async {
    emit(ServicesListLoading());
    await _loadServices(emit, event.category);
  }

  Future<void> _onRefreshServices(
      RefreshServices event,
      Emitter<ServicesListState> emit,
      ) async {
    await _loadServices(emit, null);
  }

  Future<void> _onFilterByCategory(
      FilterByCategory event,
      Emitter<ServicesListState> emit,
      ) async {
    if (state is ServicesListLoaded) {
      final currentState = state as ServicesListLoaded;

      final filteredServices = _applyFilters(
        currentState.services,
        currentState.searchQuery,
        event.category,
      );

      emit(currentState.copyWith(
        selectedCategory: event.category,
        filteredServices: filteredServices,
      ));
    }
  }

  Future<void> _onSearchServices(
      SearchServices event,
      Emitter<ServicesListState> emit,
      ) async {
    if (state is ServicesListLoaded) {
      final currentState = state as ServicesListLoaded;

      final filteredServices = _applyFilters(
        currentState.services,
        event.query,
        currentState.selectedCategory,
      );

      emit(currentState.copyWith(
        searchQuery: event.query,
        filteredServices: filteredServices,
      ));
    }
  }

  Future<void> _onClearFilters(
      ClearFilters event,
      Emitter<ServicesListState> emit,
      ) async {
    if (state is ServicesListLoaded) {
      final currentState = state as ServicesListLoaded;

      emit(currentState.copyWith(
        clearCategory: true, // Utilise le nouveau paramètre
        searchQuery: '',
        filteredServices: currentState.services,
      ));
    }
  }

  Future<void> _loadServices(
      Emitter<ServicesListState> emit,
      ServiceCategory? category,
      ) async {
    final result = await _getServicesWithStatus(category);

    result.fold(
          (failure) => emit(ServicesListError(_mapFailureToMessage(failure))),
          (services) {
        emit(ServicesListLoaded(
          services: services,
          filteredServices: services,
          selectedCategory: category,
          searchQuery: '',
        ));
      },
    );
  }

  List<ServiceWithStatus> _applyFilters(
      List<ServiceWithStatus> services,
      String searchQuery,
      ServiceCategory? category,
      ) {
    var filtered = services;

    if (category != null) {
      filtered = filtered
          .where((service) => service.provider.category == category)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered
          .where((service) =>
      service.provider.displayName.toLowerCase().startsWith(query) ||
          service.provider.name.toLowerCase().startsWith(query))
          .toList();
    }

    return filtered;
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure _:
        return 'Network error. Please check your connection.';
      case UnauthorizedFailure _:
        return 'Please log in to access services.';
      default:
        return 'Failed to load services. Please try again.';
    }
  }
}