import 'package:flutter_bloc/flutter_bloc.dart';

import 'area_form_state.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/area_draft.dart';
import '../../domain/repositories/area_repository.dart';
import '../../domain/use_cases/create_area.dart';
import '../../domain/use_cases/update_area.dart';

import '../../../services/domain/repositories/services_repository.dart';
import '../../../services/domain/use_cases/get_services_with_status.dart';
import '../../../services/domain/use_cases/get_subscription_for_service.dart';
import '../../../services/domain/use_cases/get_service_components.dart';
import '../../../services/domain/entities/service_with_status.dart';
import '../../../services/domain/entities/user_service_subscription.dart';
import '../../../services/domain/entities/service_component.dart';
import '../../../services/domain/value_objects/component_kind.dart';

class AreaFormCubit extends Cubit<AreaFormState> {
  late final CreateArea _createArea;
  late final UpdateArea _updateArea;

  late final GetServicesWithStatus _getServicesWithStatus;
  late final GetSubscriptionForService _getSubscriptionForService;
  late final GetServiceComponents _getServiceComponents;

  final Area? initialArea;

  final Map<String, bool> _subscriptionCache = {};

  final Map<String, List<ServiceComponent>> _actionComponentsCache = {};
  final Map<String, List<ServiceComponent>> _reactionComponentsCache = {};

  AreaFormCubit(
    AreaRepository areaRepository,
    ServicesRepository servicesRepository, {
    this.initialArea,
  }) : super(AreaFormInitial()) {
    _createArea = CreateArea(areaRepository);
    _updateArea = UpdateArea(areaRepository);
    _getServicesWithStatus = GetServicesWithStatus(servicesRepository);
    _getSubscriptionForService = GetSubscriptionForService(servicesRepository);
    _getServiceComponents = GetServiceComponents(servicesRepository);
  }

  bool get isSubmitting => state is AreaFormSubmitting;

  String? get lastErrorMessage =>
      state is AreaFormError ? (state as AreaFormError).message : null;

  Area? get lastSavedArea =>
      state is AreaFormSuccess ? (state as AreaFormSuccess).area : null;

  bool? isServiceSubscribedSync(String providerId) => _subscriptionCache[providerId];

  Map<String, bool> get subscriptionCache => Map.unmodifiable(_subscriptionCache);

  Future<void> primeSubscriptionCache() async {
    final either = await _getServicesWithStatus.call(null);
    either.fold(
      (_) => _subscriptionCache.clear(),
      (List<ServiceWithStatus> list) {
        _subscriptionCache
          ..clear()
          ..addEntries(list.map((s) => MapEntry(s.provider.id, s.isSubscribed)));
      },
    );
  }

  Future<UserServiceSubscription?> getSubscription(String providerId) async {
    final either = await _getSubscriptionForService.call(providerId);
    return either.fold(
      (_) {
        _subscriptionCache[providerId] = false;
        return null;
      },
      (UserServiceSubscription? sub) {
        final active = sub?.isActive == true;
        _subscriptionCache[providerId] = active;
        return sub;
      },
    );
  }

  Future<bool> checkSubscriptionActive(String providerId) async {
    final cached = _subscriptionCache[providerId];
    if (cached != null) return cached;
    final sub = await getSubscription(providerId);
    return sub?.isActive == true;
  }

  void overwriteSubscriptionInCache(String providerId, bool isSubscribed) {
    _subscriptionCache[providerId] = isSubscribed;
  }

  void clearSubscriptionCache() => _subscriptionCache.clear();

  Future<List<ServiceComponent>> getComponentsFor(
    String providerId, {
    required ComponentKind kind,
  }) async {
    final cache = kind == ComponentKind.action
        ? _actionComponentsCache
        : _reactionComponentsCache;

    final cached = cache[providerId];
    if (cached != null) return cached;

    final either = await _getServiceComponents.call(providerId, kind: kind);
    return either.fold(
      (_) {
        cache[providerId] = const <ServiceComponent>[];
        return const <ServiceComponent>[];
      },
      (List<ServiceComponent> list) {
        final byId = <String, ServiceComponent>{};
        for (final c in list) {
          byId[c.id] = c;
        }
        final deduped = byId.values.toList();
        cache[providerId] = deduped;
        return deduped;
      },
    );
  }

  List<ServiceComponent> getCachedComponents(
    String providerId, {
    required ComponentKind kind,
  }) {
    final cache = kind == ComponentKind.action
        ? _actionComponentsCache
        : _reactionComponentsCache;
    return cache[providerId] ?? const <ServiceComponent>[];
  }

  ServiceComponent? findCachedComponent(
    String providerId, {
    required ComponentKind kind,
    required String componentId,
  }) {
    final components = getCachedComponents(providerId, kind: kind);
    for (final component in components) {
      if (component.id == componentId) {
        return component;
      }
    }
    return null;
  }

  Future<void> submit({
    required String name,
    String? description,
    required AreaComponentDraft action,
    required List<AreaComponentDraft> reactions,
  }) async {
    if (reactions.isEmpty) {
      emit(const AreaFormError("Select at least one reaction component"));
      return;
    }

    emit(AreaFormSubmitting());
    try {
      final draft = AreaDraft(
        name: name,
        description: description,
        action: action,
        reactions: reactions,
      );

      if (initialArea == null) {
        final created = await _createArea(draft);
        emit(AreaFormSuccess(created));
      } else {
        final result = await _updateArea(initialArea!.id, draft);
        emit(AreaFormSuccess(result));
      }
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      emit(AreaFormError(message.isEmpty ? 'Failed to save Area' : message));
    }
  }
}
