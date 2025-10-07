import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/service_provider.dart';
import '../entities/service_component.dart';
import '../entities/component_example.dart';
import '../entities/service_subscription_exchange_result.dart';
import '../entities/service_subscription_result.dart';
import '../entities/user_service_subscription.dart';
import '../entities/about_info.dart';
import '../entities/service_with_status.dart';
import '../entities/service_identity_summary.dart';
import '../value_objects/service_category.dart';
import '../value_objects/component_kind.dart';

abstract class ServicesRepository {
  Future<Either<Failure, List<ServiceProvider>>> getAvailableServices({
    ServiceCategory? category,
  });

  Future<Either<Failure, ServiceProvider>> getServiceDetails(String serviceId);

  Future<Either<Failure, List<ServiceComponent>>> getServiceComponents(
      String serviceId, {
        ComponentKind? kind,
        bool onlySubscribed = false,
      });

  Future<Either<Failure, List<ComponentExample>>> getComponentExamples(
      String componentId,
      );

  Future<Either<Failure, AboutInfo>> getAboutInfo();

  Future<Either<Failure, List<UserServiceSubscription>>> getUserSubscriptions();

  Future<Either<Failure, ServiceSubscriptionResult>> subscribeToService({
    required String serviceId,
    List<String> requestedScopes = const [],
    String? redirectUri,
    String? state,
    bool? usePkce,
  });

  Future<Either<Failure, ServiceSubscriptionExchangeResult>>
      completeServiceSubscription({
    required String serviceId,
    required String code,
    String? codeVerifier,
    String? redirectUri,
  });

  Future<Either<Failure, bool>> unsubscribeFromService(String subscriptionId);

  Future<Either<Failure, UserServiceSubscription?>> getSubscriptionForService(
      String serviceId,
      );

  Future<Either<Failure, List<ServiceWithStatus>>> getServicesWithStatus({
    ServiceCategory? category,
  });

  Future<Either<Failure, List<ServiceIdentitySummary>>> getConnectedIdentities();
}
