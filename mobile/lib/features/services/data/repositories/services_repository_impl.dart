import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/services_repository.dart';
import '../../domain/entities/service_provider.dart';
import '../../domain/entities/service_component.dart';
import '../../domain/entities/component_example.dart';
import '../../domain/entities/user_service_subscription.dart';
import '../../domain/entities/about_info.dart';
import '../../domain/entities/service_with_status.dart';
import '../../domain/value_objects/service_category.dart';
import '../../domain/value_objects/component_kind.dart';
import '../../domain/value_objects/auth_kind.dart';
import '../../domain/value_objects/subscription_status.dart';
import 'package:collection/collection.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final List<ServiceProvider> _providers = [
    ServiceProvider(
      id: "1",
      name: "google",
      displayName: "Google",
      category: ServiceCategory.productivity,
      oauthType: AuthKind.oauth2,
      authConfig: {"clientId": "xxx"},
      isEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ServiceProvider(
      id: "2",
      name: "slack",
      displayName: "Slack",
      category: ServiceCategory.communication,
      oauthType: AuthKind.oauth2,
      authConfig: {"clientId": "yyy"},
      isEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ServiceProvider(
      id: "3",
      name: "dropbox",
      displayName: "Dropbox",
      category: ServiceCategory.storage,
      oauthType: AuthKind.oauth2,
      authConfig: {},
      isEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final List<UserServiceSubscription> _subscriptions = [];

  @override
  Future<Either<Failure, List<ServiceProvider>>> getAvailableServices({
    ServiceCategory? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final result = category == null
        ? _providers
        : _providers.where((p) => p.category == category).toList();
    return Right(result);
  }

  @override
  Future<Either<Failure, ServiceProvider>> getServiceDetails(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final service = _providers.firstWhere((s) => s.id == serviceId);
      return Right(service);
    } catch (e) {
      return Left(UnknownFailure("Service not found"));
    }
  }

  @override
  Future<Either<Failure, List<ServiceComponent>>> getServiceComponents(
      String serviceId, {
        ComponentKind? kind,
      }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final components = [
      ServiceComponent(
        id: "c1",
        providerId: serviceId,
        kind: ComponentKind.action,
        name: "new_message",
        displayName: "New Message",
        description: "Triggers when a new message is received",
        version: 1,
        inputSchema: const {},
        outputSchema: const {},
        metadata: const {},
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ServiceComponent(
        id: "c2",
        providerId: serviceId,
        kind: ComponentKind.reaction,
        name: "send_notification",
        displayName: "Send Notification",
        description: "Send notification to user",
        version: 1,
        inputSchema: const {},
        outputSchema: const {},
        metadata: const {},
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final filtered = kind == null
        ? components
        : components.where((c) => c.kind == kind).toList();

    return Right(filtered);
  }

  @override
  Future<Either<Failure, List<ComponentExample>>> getComponentExamples(
      String componentId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return Right([
      ComponentExample(
        id: "ex1",
        componentId: componentId,
        exampleInput: {"text": "example input"},
        exampleOutput: {"result": "example output"},
      ),
    ]);
  }

  @override
  Future<Either<Failure, AboutInfo>> getAboutInfo() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return Right(AboutInfo(
      clientHost: "127.0.0.1",
      currentTime: DateTime.now().millisecondsSinceEpoch,
      services: _providers
          .map((s) => AboutService(
        name: s.name,
        actions: const [
          AboutAction(name: "fake_action", description: "A fake action"),
        ],
        reactions: const [
          AboutReaction(name: "fake_reaction", description: "A fake reaction"),
        ],
      ))
          .toList(),
    ));
  }

  @override
  Future<Either<Failure, List<UserServiceSubscription>>> getUserSubscriptions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Right(_subscriptions);
  }

  @override
  Future<Either<Failure, UserServiceSubscription>> subscribeToService({
    required String serviceId,
    required List<String> requestedScopes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final subscription = UserServiceSubscription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: "test-user",
      providerId: serviceId,
      identityId: null,
      status: SubscriptionStatus.active,
      scopeGrants: requestedScopes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _subscriptions.add(subscription);

    return Right(subscription);
  }

  @override
  Future<Either<Failure, bool>> unsubscribeFromService(String subscriptionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _subscriptions.removeWhere((sub) => sub.id == subscriptionId);
    return const Right(true);
  }

  @override
  Future<Either<Failure, UserServiceSubscription?>> getSubscriptionForService(
      String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sub = _subscriptions.firstWhereOrNull((s) => s.providerId == serviceId);
    return Right(sub);
  }

  @override
  Future<Either<Failure, List<ServiceWithStatus>>> getServicesWithStatus({
    ServiceCategory? category,
  }) async {
    final servicesResult = await getAvailableServices(category: category);
    final subscriptionsResult = await getUserSubscriptions();

    return servicesResult.fold(
          (failure) => Left(failure),
          (services) => subscriptionsResult.fold(
            (failure) => Left(failure),
            (subs) {
          final result = services.map((service) {
            final sub = subs.firstWhereOrNull(
                  (s) => s.providerId == service.id,
            );
            return ServiceWithStatus(
              provider: service,
              isSubscribed: sub != null,
              subscription: sub,
            );
          }).toList();
          return Right(result);
        },
      ),
    );
  }
}