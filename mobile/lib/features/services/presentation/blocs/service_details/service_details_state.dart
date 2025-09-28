import 'package:equatable/equatable.dart';
import '../../../domain/entities/service_provider.dart';
import '../../../domain/entities/service_component.dart';
import '../../../domain/entities/user_service_subscription.dart';
import '../../../domain/value_objects/component_kind.dart';

abstract class ServiceDetailsState extends Equatable {
  const ServiceDetailsState();

  @override
  List<Object?> get props => [];
}

class ServiceDetailsInitial extends ServiceDetailsState {}

class ServiceDetailsLoading extends ServiceDetailsState {}

class ServiceDetailsLoaded extends ServiceDetailsState {
  final ServiceProvider service;
  final UserServiceSubscription? subscription;
  final List<ServiceComponent> components;
  final List<ServiceComponent> filteredComponents;
  final ComponentKind? selectedComponentKind;
  final String searchQuery;

  const ServiceDetailsLoaded({
    required this.service,
    this.subscription,
    required this.components,
    required this.filteredComponents,
    this.selectedComponentKind,
    required this.searchQuery,
  });

  bool get isSubscribed => subscription?.isActive ?? false;

  List<ServiceComponent> get actions =>
      filteredComponents.where((c) => c.isAction).toList();

  List<ServiceComponent> get reactions =>
      filteredComponents.where((c) => c.isReaction).toList();

  ServiceDetailsLoaded copyWith({
    ServiceProvider? service,
    UserServiceSubscription? subscription,
    List<ServiceComponent>? components,
    List<ServiceComponent>? filteredComponents,
    ComponentKind? selectedComponentKind,
    String? searchQuery,
  }) {
    return ServiceDetailsLoaded(
      service: service ?? this.service,
      subscription: subscription ?? this.subscription,
      components: components ?? this.components,
      filteredComponents: filteredComponents ?? this.filteredComponents,
      selectedComponentKind: selectedComponentKind ?? this.selectedComponentKind,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    service,
    subscription,
    components,
    filteredComponents,
    selectedComponentKind,
    searchQuery,
  ];
}

class ServiceDetailsError extends ServiceDetailsState {
  final String message;

  const ServiceDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}