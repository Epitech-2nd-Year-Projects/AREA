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
import '../../../services/domain/use_cases/get_connected_identities.dart';
import '../../../services/domain/entities/service_with_status.dart';
import '../../../services/domain/entities/user_service_subscription.dart';
import '../../../services/domain/entities/service_component.dart';
import '../../../services/domain/entities/component_parameter.dart';
import '../../../services/domain/entities/service_identity_summary.dart';
import '../../../services/domain/value_objects/component_kind.dart';

class AreaFormCubit extends Cubit<AreaFormState> {
  late final CreateArea _createArea;
  late final UpdateArea _updateArea;

  late final GetServicesWithStatus _getServicesWithStatus;
  late final GetSubscriptionForService _getSubscriptionForService;
  late final GetServiceComponents _getServiceComponents;
  late final GetConnectedIdentities _getConnectedIdentities;

  final Area? initialArea;

  final Map<String, bool> _subscriptionCache = {};

  final Map<String, List<ServiceComponent>> _actionComponentsCache = {};
  final Map<String, List<ServiceComponent>> _reactionComponentsCache = {};
  Future<List<ServiceIdentitySummary>>? _connectedIdentitiesFuture;
  List<ServiceIdentitySummary>? _connectedIdentitiesCache;
  final Map<String, String> _providerIdentityCache = {};

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
    _getConnectedIdentities = GetConnectedIdentities(servicesRepository);
  }

  bool get isSubmitting => state is AreaFormSubmitting;

  String? get lastErrorMessage =>
      state is AreaFormError ? (state as AreaFormError).message : null;

  Area? get lastSavedArea =>
      state is AreaFormSuccess ? (state as AreaFormSuccess).area : null;

  bool? isServiceSubscribedSync(String providerId) =>
      _subscriptionCache[providerId];

  Map<String, bool> get subscriptionCache =>
      Map.unmodifiable(_subscriptionCache);

  Future<void> primeSubscriptionCache() async {
    await Future.wait([_primeSubscriptions(), _loadConnectedIdentities()]);
  }

  Future<void> _primeSubscriptions() async {
    final either = await _getServicesWithStatus.call(null);
    either.fold((_) => _subscriptionCache.clear(), (
      List<ServiceWithStatus> list,
    ) {
      _subscriptionCache
        ..clear()
        ..addEntries(list.map((s) => MapEntry(s.provider.id, s.isSubscribed)));
    });
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

  void clearSubscriptionCache() {
    _subscriptionCache.clear();
    _providerIdentityCache.clear();
  }

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

  Future<Map<String, dynamic>> suggestParametersFor(
    ServiceComponent component,
  ) async {
    final suggestions = <String, dynamic>{};
    final identityId = await _resolveIdentityIdForComponent(component);

    if (identityId != null && identityId.isNotEmpty) {
      for (final param in component.parameters) {
        if (_isIdentityParameter(param)) {
          suggestions[param.key] = identityId;
        }
      }
    }

    return suggestions;
  }

  Future<String?> _resolveIdentityIdForComponent(
    ServiceComponent component,
  ) async {
    final metadataProvider = _extractProviderFromMetadata(component);
    final providerKeys = _collectProviderKeys({
      component.provider.id,
      component.provider.name,
      component.provider.displayName,
      metadataProvider,
    });

    for (final key in providerKeys) {
      final cached = _providerIdentityCache[key];
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final identity = await _findIdentityForComponent(component, providerKeys);
    if (identity != null) {
      for (final key in providerKeys) {
        _providerIdentityCache[key] = identity.id;
      }
      return identity.id;
    }

    final providerCandidates = <String>{};
    if (component.provider.id.isNotEmpty) {
      providerCandidates.add(component.provider.id);
    }
    if (component.provider.name.isNotEmpty) {
      providerCandidates.add(component.provider.name);
    }
    if (component.provider.displayName.isNotEmpty) {
      providerCandidates.add(component.provider.displayName);
    }
    if (metadataProvider != null && metadataProvider.isNotEmpty) {
      providerCandidates.add(metadataProvider);
    }

    for (final key in providerKeys) {
      if (key.isNotEmpty) {
        providerCandidates.add(key);
        providerCandidates.add(key.replaceAll('_', '-'));
      }
    }

    for (final candidate in providerCandidates) {
      final subscription = await getSubscription(candidate);
      final identityId = subscription?.identityId;
      if (identityId != null && identityId.isNotEmpty) {
        for (final key in providerKeys) {
          _providerIdentityCache[key] = identityId;
        }
        return identityId;
      }
    }

    return null;
  }

  Future<ServiceIdentitySummary?> _findIdentityForComponent(
    ServiceComponent component,
    Set<String> providerKeys,
  ) async {
    final identities = await _loadConnectedIdentities();
    if (identities.isEmpty) {
      return null;
    }

    for (final identity in identities) {
      final identityKeys = _expandProviderKeys(identity.provider);
      if (providerKeys.any(identityKeys.contains)) {
        return identity;
      }
    }

    return null;
  }

  Future<List<ServiceIdentitySummary>> _loadConnectedIdentities() async {
    if (_connectedIdentitiesCache != null) {
      return _connectedIdentitiesCache!;
    }

    _connectedIdentitiesFuture ??= _getConnectedIdentities.call().then((
      either,
    ) {
      final identities = either.fold(
        (_) => <ServiceIdentitySummary>[],
        (list) => list,
      );
      _connectedIdentitiesCache = identities;
      return identities;
    });

    return _connectedIdentitiesFuture!;
  }

  Set<String> _collectProviderKeys(Iterable<String?> values) {
    final keys = <String>{};
    for (final value in values) {
      if (value == null || value.trim().isEmpty) continue;
      keys.addAll(_expandProviderKeys(value));
    }
    return keys;
  }

  Set<String> _expandProviderKeys(String value) {
    final normalized = _normalizeProviderKey(value);
    if (normalized.isEmpty) {
      return <String>{};
    }

    final keys = <String>{normalized, normalized.replaceAll('_', '')};
    final segments = normalized
        .split('_')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length > 1) {
      for (var i = 1; i <= segments.length; i++) {
        keys.add(segments.take(i).join('_'));
      }
    }
    return keys;
  }

  String _normalizeProviderKey(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized;
  }

  bool _isIdentityParameter(ComponentParameter param) {
    final key = param.key.toLowerCase();
    if (key.contains('identityid') ||
        key == 'identity' ||
        (key.endsWith('identity') && key.contains('id'))) {
      return true;
    }

    final label = param.label.toLowerCase();
    if (label.contains('identity')) {
      return true;
    }

    final type = param.type.toLowerCase();
    if (type == 'identity') {
      return true;
    }

    for (final entryKey in ['source', 'type', 'kind', 'category']) {
      final value = param.extras[entryKey];
      if (value is String && value.toLowerCase().contains('identity')) {
        return true;
      }
    }

    final description = param.description?.toLowerCase() ?? '';
    if (description.contains('identity')) {
      return true;
    }

    return false;
  }

  String? _extractProviderFromMetadata(ServiceComponent component) {
    if (component.metadata.isEmpty) {
      return null;
    }

    for (final key in ['providerId', 'provider', 'service', 'serviceId']) {
      final value = component.metadata[key];
      if (value is String && value.isNotEmpty) {
        return value;
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
