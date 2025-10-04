import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/about_info.dart';
import '../../domain/entities/component_example.dart';
import '../../domain/entities/service_component.dart';
import '../../domain/entities/service_provider.dart';
import '../../domain/entities/service_with_status.dart';
import '../../domain/entities/user_service_subscription.dart';
import '../../domain/repositories/services_repository.dart';
import '../../domain/value_objects/component_kind.dart';
import '../../domain/value_objects/service_category.dart';
import '../../domain/value_objects/subscription_status.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/service_component_model.dart';
import '../models/service_provider_model.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;

  ServicesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AboutInfo>> getAboutInfo() async {
    try {
      final aboutInfoModel = await remoteDataSource.getAboutInfo();
      return Right(aboutInfoModel.toEntity());
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
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
      return Left(NetworkFailure(e.toString()));
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
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceComponent>>> getServiceComponents(
      String serviceId, {
        ComponentKind? kind,
      }) async {
    try {
      final aboutInfoModel = await remoteDataSource.getAboutInfo();
      final service = aboutInfoModel.server.services.firstWhere(
            (s) => s.name.toLowerCase() == serviceId.toLowerCase() ||
            s.name.toLowerCase().replaceAll('_', '') == serviceId.toLowerCase(),
        orElse: () => throw Exception('Service not found'),
      );

      final List<ServiceComponent> components = [];
      if (kind == null || kind == ComponentKind.action) {
        for (var action in service.actions) {
          final component = ServiceComponentModel.fromAboutComponent(
            providerId: serviceId,
            kind: ComponentKind.action,
            name: action.name,
            description: action.description,
          ).toEntity();
          components.add(component);
        }
      }

      if (kind == null || kind == ComponentKind.reaction) {
        for (var reaction in service.reactions) {
          final component = ServiceComponentModel.fromAboutComponent(
            providerId: serviceId,
            kind: ComponentKind.reaction,
            name: reaction.name,
            description: reaction.description,
          ).toEntity();
          components.add(component);
        }
      }

      return Right(components);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
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
            return ServiceWithStatus(
              provider: service,
              isSubscribed: false,
              subscription: null,
            );
          }).toList();
          return Right(servicesWithStatus);
        },
      );
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserServiceSubscription>>>
  getUserSubscriptions() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, UserServiceSubscription?>> getSubscriptionForService(
      String serviceId,
      ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserServiceSubscription>> subscribeToService({
    required String serviceId,
    required List<String> requestedScopes,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final subscription = UserServiceSubscription(
        id: 'temp_sub_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        providerId: serviceId,
        identityId: 'temp_identity',
        status: SubscriptionStatus.active,
        scopeGrants: requestedScopes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Right(subscription);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> unsubscribeFromService(
      String subscriptionId,
      ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(true);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}