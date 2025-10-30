import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/about_info.dart';
import '../../domain/entities/component_example.dart';
import '../../domain/entities/service_component.dart';
import '../../domain/entities/service_provider.dart';
import '../../domain/entities/service_subscription_exchange_result.dart';
import '../../domain/entities/service_subscription_result.dart';
import '../../domain/entities/service_with_status.dart';
import '../../domain/entities/user_service_subscription.dart';
import '../../domain/entities/service_identity_summary.dart';
import '../../domain/repositories/services_repository.dart';
import '../../domain/value_objects/component_kind.dart';
import '../../domain/value_objects/service_category.dart';
import '../../domain/value_objects/subscription_status.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/about_info_model.dart';
import '../models/service_component_model.dart';
import '../models/service_provider_model.dart';
import '../models/user_service_subscription_model.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;
  final Map<String, UserServiceSubscription> _subscriptionCache = {};

  ServicesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AboutInfo>> getAboutInfo() async {
    try {
      final aboutInfoModel = await remoteDataSource.getAboutInfo();
      return Right(aboutInfoModel.toEntity());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<ServiceProvider>>> getAvailableServices({
    ServiceCategory? category,
  }) async {
    try {
      final serviceDataList = await remoteDataSource.listServiceProviders();
      final services = serviceDataList
          .map((data) => ServiceProviderModel.fromJson(data).toEntity())
          .toList();

      if (category != null) {
        final filtered = services.where((s) => s.category == category).toList();
        return Right(filtered);
      }

      return Right(services);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, ServiceProvider>> getServiceDetails(
    String serviceId,
  ) async {
    try {
      final serviceDataList = await remoteDataSource.listServiceProviders();

      final normalizedId = _normalizeServiceKey(serviceId);
      final serviceData = serviceDataList.firstWhere((data) {
        final id = data['id']?.toString().toLowerCase() ?? '';
        final name = data['name']?.toString().toLowerCase() ?? '';
        return _normalizeServiceKey(id) == normalizedId ||
            _normalizeServiceKey(name) == normalizedId;
      }, orElse: () => throw Exception('Service not found'));

      final serviceProvider = ServiceProviderModel.fromJson(
        serviceData,
      ).toEntity();
      return Right(serviceProvider);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<ServiceComponent>>> getServiceComponents(
    String serviceId, {
    ComponentKind? kind,
    bool onlySubscribed = false,
  }) async {
    final normalizedId = _normalizeServiceKey(serviceId);

    try {
      final models = await _fetchComponentsFromApi(
        providerId: normalizedId,
        kind: kind,
        onlyAvailable: onlySubscribed,
      );

      final components = models.map((model) => model.toEntity()).toList();
      return Right(components);
    } catch (error) {
      final primaryFailure = _mapError(error);

      if (primaryFailure is NetworkFailure && onlySubscribed) {
        try {
          final models = await _fetchComponentsFromApi(
            providerId: normalizedId,
            kind: kind,
            onlyAvailable: false,
          );

          final components = models.map((model) => model.toEntity()).toList();
          return Right(components);
        } catch (secondaryError) {
          return await _handleComponentsError(secondaryError, serviceId, kind);
        }
      }

      return await _handleComponentsError(error, serviceId, kind);
    }
  }

  @override
  Future<Either<Failure, List<ComponentExample>>> getComponentExamples(
    String componentId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<ServiceWithStatus>>> getServicesWithStatus({
    ServiceCategory? category,
  }) async {
    try {
      final servicesResult = await getAvailableServices(category: category);

      final availableComponentsResult = await remoteDataSource.listComponents(
        onlyAvailable: true,
      );

      final Set<String> subscribedProviderIdentifiers = {};
      for (final component in availableComponentsResult) {
        subscribedProviderIdentifiers.add(
          _normalizeServiceKey(component.provider.id),
        );
        subscribedProviderIdentifiers.add(
          _normalizeServiceKey(component.provider.name),
        );
        subscribedProviderIdentifiers.add(
          _normalizeServiceKey(component.provider.displayName),
        );
      }

      return servicesResult.fold((failure) => Left(failure), (services) {
        final servicesWithStatus = services.map((service) {
          final normalizedId = _normalizeServiceKey(service.id);
          final normalizedName = _normalizeServiceKey(service.name);
          final normalizedDisplayName = _normalizeServiceKey(
            service.displayName,
          );

          final isSubscribed =
              subscribedProviderIdentifiers.contains(normalizedId) ||
              subscribedProviderIdentifiers.contains(normalizedName) ||
              subscribedProviderIdentifiers.contains(normalizedDisplayName);

          final cachedSubscription =
              _subscriptionCache[normalizedId] ??
              _subscriptionCache[normalizedName] ??
              _subscriptionCache[normalizedDisplayName];

          UserServiceSubscription? subscription = cachedSubscription;

          if (isSubscribed && subscription == null) {
            final now = DateTime.now();
            subscription = UserServiceSubscription(
              id: normalizedId,
              providerId: normalizedId,
              status: SubscriptionStatus.active,
              scopeGrants: const [],
              createdAt: now,
              updatedAt: now,
            );
          }

          return ServiceWithStatus(
            provider: service,
            isSubscribed: isSubscribed,
            subscription: subscription,
          );
        }).toList();
        return Right(servicesWithStatus);
      });
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<ServiceIdentitySummary>>>
  getConnectedIdentities() async {
    try {
      final models = await remoteDataSource.listIdentities();
      final identities = models.map((model) => model.toEntity()).toList();
      return Right(identities);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<UserServiceSubscription>>>
  getUserSubscriptions() async {
    try {
      final subscriptionDataList = await remoteDataSource
          .listServiceSubscriptions();

      final subscriptions = subscriptionDataList
          .map((data) => UserServiceSubscriptionModel.fromJson(data).toEntity())
          .toList();

      // Update cache
      for (final subscription in subscriptions) {
        _subscriptionCache[_normalizeServiceKey(subscription.id)] =
            subscription;
      }

      return Right(subscriptions);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, UserServiceSubscription?>> getSubscriptionForService(
    String serviceId,
  ) async {
    try {
      final normalizedId = _normalizeServiceKey(serviceId);

      final availableComponentsResult = await remoteDataSource.listComponents(
        onlyAvailable: true,
      );

      final Set<String> subscribedProviderIdentifiers = {};
      for (final component in availableComponentsResult) {
        subscribedProviderIdentifiers.add(
          _normalizeServiceKey(component.provider.id),
        );
        subscribedProviderIdentifiers.add(
          _normalizeServiceKey(component.provider.name),
        );
        subscribedProviderIdentifiers.add(
          _normalizeServiceKey(component.provider.displayName),
        );
      }

      final isSubscribed = subscribedProviderIdentifiers.contains(normalizedId);

      if (!isSubscribed) {
        return const Right(null);
      }

      final subscription = _subscriptionCache[normalizedId];
      if (subscription != null) {
        return Right(subscription);
      }

      final now = DateTime.now();
      final newSubscription = UserServiceSubscription(
        id: normalizedId,
        providerId: normalizedId,
        status: SubscriptionStatus.active,
        scopeGrants: const [],
        createdAt: now,
        updatedAt: now,
      );

      return Right(newSubscription);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, ServiceSubscriptionResult>> subscribeToService({
    required String serviceId,
    List<String> requestedScopes = const [],
    String? redirectUri,
    String? state,
    bool? usePkce,
  }) async {
    try {
      final normalizedId = _normalizeServiceKey(serviceId);

      final response = await remoteDataSource.subscribeToService(
        provider: normalizedId,
        scopes: requestedScopes,
        redirectUri: redirectUri,
        state: state,
        usePkce: usePkce,
      );

      final result = response.toEntity();
      final subscription = result.subscription;
      if (subscription != null) {
        _subscriptionCache[normalizedId] = subscription;
      }
      return Right(result);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, ServiceSubscriptionExchangeResult>>
  completeServiceSubscription({
    required String serviceId,
    required String code,
    String? codeVerifier,
    String? redirectUri,
  }) async {
    try {
      final normalizedId = _normalizeServiceKey(serviceId);

      final result = await remoteDataSource.completeSubscription(
        provider: normalizedId,
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );

      _subscriptionCache[normalizedId] = result.subscription;

      return Right(result);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> unsubscribeFromService(
    String subscriptionId,
  ) async {
    try {
      // The subscriptionId is typically the provider name (normalized)
      await remoteDataSource.unsubscribeFromService(subscriptionId);
      _subscriptionCache.removeWhere(
        (_, subscription) => subscription.id == subscriptionId,
      );
      return const Right(true);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  Failure _mapError(Object error) {
    if (error is Failure) {
      return error;
    }
    return NetworkFailure(error.toString());
  }

  Future<Either<Failure, List<ServiceComponent>>> _handleComponentsError(
    Object error,
    String serviceId,
    ComponentKind? kind,
  ) async {
    final failure = _mapError(error);
    if (failure is NetworkFailure) {
      try {
        final fallback = await _loadComponentsFromAbout(
          serviceId,
          fallbackKind: kind,
        );
        return Right(fallback.map((model) => model.toEntity()).toList());
      } catch (_) {}
    }
    return Left(failure);
  }

  Future<List<ServiceComponentModel>> _loadComponentsFromAbout(
    String serviceId, {
    ComponentKind? fallbackKind,
  }) async {
    final about = await remoteDataSource.getAboutInfo();
    final normalizedId = _normalizeServiceKey(serviceId);

    final service = about.server.services.firstWhere(
      (s) => _normalizeServiceKey(s.name) == normalizedId,
      orElse: () => AboutServiceModel(
        name: normalizedId,
        actions: const <AboutActionModel>[],
        reactions: const <AboutReactionModel>[],
      ),
    );

    final components = <ServiceComponentModel>[];
    if (fallbackKind == null || fallbackKind == ComponentKind.action) {
      for (final action in service.actions) {
        components.add(
          ServiceComponentModel.fromAboutComponent(
            providerId: normalizedId,
            kind: ComponentKind.action,
            name: action.name,
            description: action.description,
          ),
        );
      }
    }
    if (fallbackKind == null || fallbackKind == ComponentKind.reaction) {
      for (final reaction in service.reactions) {
        components.add(
          ServiceComponentModel.fromAboutComponent(
            providerId: normalizedId,
            kind: ComponentKind.reaction,
            name: reaction.name,
            description: reaction.description,
          ),
        );
      }
    }

    return components;
  }

  Future<List<ServiceComponentModel>> _fetchComponentsFromApi({
    required String providerId,
    ComponentKind? kind,
    required bool onlyAvailable,
  }) async {
    final normalizedProvider = _normalizeServiceKey(providerId);
    final components = await remoteDataSource.listComponents(
      onlyAvailable: onlyAvailable,
    );

    final matches = components.where((component) {
      if (!_componentBelongsToProvider(component, normalizedProvider)) {
        return false;
      }
      if (kind != null && component.kind != kind) {
        return false;
      }
      return true;
    }).toList();

    return matches;
  }

  String _normalizeServiceKey(String value) {
    return value.toLowerCase().replaceAll(' ', '_');
  }

  bool _componentBelongsToProvider(
    ServiceComponentModel component,
    String normalizedProvider,
  ) {
    final providerId = _normalizeServiceKey(component.provider.id);
    final providerName = _normalizeServiceKey(component.provider.name);
    final providerDisplay = _normalizeServiceKey(
      component.provider.displayName,
    );

    if (providerId == normalizedProvider ||
        providerName == normalizedProvider ||
        providerDisplay == normalizedProvider) {
      return true;
    }

    final componentIdPrefix = '${normalizedProvider}_';
    return component.id.toLowerCase().startsWith(componentIdPrefix);
  }
}
