import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/repositories/services_repository.dart';
import '../../../domain/use_cases/get_service_details.dart';
import '../../../domain/use_cases/get_service_components.dart';
import '../../../domain/use_cases/get_subscription_for_service.dart';
import '../../../domain/entities/service_provider.dart';
import '../../../domain/entities/service_component.dart';
import '../../../domain/entities/user_service_subscription.dart';
import '../../../domain/value_objects/component_kind.dart';
import 'service_details_event.dart';
import 'service_details_state.dart';

class ServiceDetailsBloc extends Bloc<ServiceDetailsEvent, ServiceDetailsState> {
  late final GetServiceDetails _getServiceDetails;
  late final GetServiceComponents _getServiceComponents;
  late final GetSubscriptionForService _getSubscriptionForService;

  ServiceDetailsBloc(ServicesRepository repository) : super(ServiceDetailsInitial()) {
    _getServiceDetails = GetServiceDetails(repository);
    _getServiceComponents = GetServiceComponents(repository);
    _getSubscriptionForService = GetSubscriptionForService(repository);

    on<LoadServiceDetails>(_onLoadServiceDetails);
    on<LoadServiceComponents>(_onLoadServiceComponents);
    on<FilterComponents>(_onFilterComponents);
    on<SearchComponents>(_onSearchComponents);
  }

  Future<void> _onLoadServiceDetails(
      LoadServiceDetails event,
      Emitter<ServiceDetailsState> emit,
      ) async {
    emit(ServiceDetailsLoading());

    final results = await Future.wait([
      _getServiceDetails(event.serviceId),
      _getSubscriptionForService(event.serviceId),
    ]);

    final serviceResult = results[0] as Either<Failure, ServiceProvider>;
    final subscriptionResult = results[1] as Either<Failure, UserServiceSubscription?>;

    serviceResult.fold(
          (failure) => emit(ServiceDetailsError(_mapFailureToMessage(failure))),
          (service) {
        UserServiceSubscription? subscription;
        subscriptionResult.fold(
              (failure) => {},
              (sub) => subscription = sub,
        );

        emit(ServiceDetailsLoaded(
          service: service,
          subscription: subscription,
          components: [],
          filteredComponents: [],
          selectedComponentKind: null,
          searchQuery: '',
        ));

        add(LoadServiceComponents(event.serviceId));
      },
    );
  }

  Future<void> _onLoadServiceComponents(
      LoadServiceComponents event,
      Emitter<ServiceDetailsState> emit,
      ) async {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      final result = await _getServiceComponents(event.serviceId);

      result.fold(
            (failure) => {},
            (components) => emit(currentState.copyWith(
          components: components,
          filteredComponents: components,
        )),
      );
    }
  }

  Future<void> _onFilterComponents(
      FilterComponents event,
      Emitter<ServiceDetailsState> emit,
      ) async {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      final filteredComponents = _applyFilters(
        currentState.components,
        currentState.searchQuery,
        event.kind,
      );

      emit(currentState.copyWith(
        selectedComponentKind: event.kind,
        filteredComponents: filteredComponents,
      ));
    }
  }

  Future<void> _onSearchComponents(
      SearchComponents event,
      Emitter<ServiceDetailsState> emit,
      ) async {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      final filteredComponents = _applyFilters(
        currentState.components,
        event.query,
        currentState.selectedComponentKind,
      );

      emit(currentState.copyWith(
        searchQuery: event.query,
        filteredComponents: filteredComponents,
      ));
    }
  }

  List<ServiceComponent> _applyFilters(
      List<ServiceComponent> components,
      String searchQuery,
      ComponentKind? kind,
      ) {
    var filtered = components;

    if (kind != null) {
      filtered = filtered.where((component) => component.kind == kind).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered
          .where((component) =>
      component.name.toLowerCase().contains(query) ||
          component.displayName.toLowerCase().contains(query) ||
          component.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure _:
        return 'Network error. Please check your connection.';
      case UnauthorizedFailure _:
        return 'Please log in to access service details.';
      default:
        return 'Failed to load service details. Please try again.';
    }
  }
}