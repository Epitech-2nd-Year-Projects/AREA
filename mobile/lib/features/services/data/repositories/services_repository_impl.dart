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
import '../../domain/repositories/services_repository.dart';
import '../../domain/value_objects/component_kind.dart';
import '../../domain/value_objects/service_category.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/about_info_model.dart';
import '../models/service_component_model.dart';
import '../models/service_provider_model.dart';

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
      final aboutInfoModel = await remoteDataSource.getAboutInfo();
      final services = aboutInfoModel.server.services
          .map((s) => ServiceProviderModel.fromServiceName(s.name).toEntity())
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
      final aboutInfoModel = await remoteDataSource.getAboutInfo();
      final service = aboutInfoModel.server.services.firstWhere(
            (s) => s.name.toLowerCase() == serviceId.toLowerCase() ||
            s.name.toLowerCase().replaceAll('_', '') == serviceId.toLowerCase(),
        orElse: () => throw Exception('Service not found'),
      );

      final serviceProvider =
      ServiceProviderModel.fromServiceName(service.name).toEntity();
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
          return await _handleComponentsError(
            secondaryError,
            serviceId,
            kind,
          );
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

      return servicesResult.fold(
            (failure) => Left(failure),
            (services) {
          final servicesWithStatus = services.map((service) {
            final key = _normalizeServiceKey(service.id);
            final fallbackKey = _normalizeServiceKey(service.name);
            final cachedSubscription = _subscriptionCache[key] ??
                _subscriptionCache[fallbackKey];
            return ServiceWithStatus(
              provider: service,
              isSubscribed: cachedSubscription?.isActive ?? false,
              subscription: cachedSubscription,
            );
          }).toList();
          return Right(servicesWithStatus);
        },
      );
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<UserServiceSubscription>>>
      getUserSubscriptions() async {
    try {
      final seen = <String>{};
      final subscriptions = _subscriptionCache.values.where((subscription) {
        final isNew = seen.add(subscription.id);
        return isNew;
      }).toList();
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
      final subscription = _subscriptionCache[serviceId] ??
          _subscriptionCache[_normalizeServiceKey(serviceId)];
      return Right(subscription);
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
      await Future.delayed(const Duration(milliseconds: 500));
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
    return await remoteDataSource.listComponents(
      kind: kind,
      provider: providerId,
      onlyAvailable: onlyAvailable,
    );
  }

  String _normalizeServiceKey(String value) {
    return value.toLowerCase().replaceAll(' ', '_');
  }
}
