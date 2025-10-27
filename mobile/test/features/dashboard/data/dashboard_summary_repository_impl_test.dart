import 'package:area/core/error/failures.dart';
import 'package:area/features/areas/domain/entities/area.dart';
import 'package:area/features/areas/domain/entities/area_component_binding.dart';
import 'package:area/features/areas/domain/entities/area_status.dart';
import 'package:area/features/areas/domain/repositories/area_repository.dart';
import 'package:area/features/dashboard/data/repositories/dashboard_summary_repository_impl.dart';
import 'package:area/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:area/features/services/domain/entities/about_info.dart';
import 'package:area/features/services/domain/entities/service_component.dart';
import 'package:area/features/services/domain/entities/service_identity_summary.dart';
import 'package:area/features/services/domain/entities/service_provider.dart';
import 'package:area/features/services/domain/entities/service_provider_summary.dart';
import 'package:area/features/services/domain/entities/service_with_status.dart';
import 'package:area/features/services/domain/entities/user_service_subscription.dart';
import 'package:area/features/services/domain/repositories/services_repository.dart';
import 'package:area/features/services/domain/value_objects/auth_kind.dart';
import 'package:area/features/services/domain/value_objects/component_kind.dart';
import 'package:area/features/services/domain/value_objects/service_category.dart';
import 'package:area/features/services/domain/value_objects/subscription_status.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAreaRepository extends Mock implements AreaRepository {}

class _MockServicesRepository extends Mock implements ServicesRepository {}

void main() {
  late DashboardSummaryRepositoryImpl repository;
  late _MockAreaRepository areaRepository;
  late _MockServicesRepository servicesRepository;

  setUp(() {
    areaRepository = _MockAreaRepository();
    servicesRepository = _MockServicesRepository();
    repository = DashboardSummaryRepositoryImpl(
      areaRepository: areaRepository,
      servicesRepository: servicesRepository,
    );
  });

  group('DashboardSummaryRepositoryImpl', () {
    test('builds summary aggregates from repositories', () async {
      final aboutInfo = AboutInfo(
        clientHost: '127.0.0.1',
        currentTime: DateTime.now().millisecondsSinceEpoch,
        services: const [
          AboutService(name: 'google', actions: [], reactions: []),
        ],
      );

      final googleProvider = ServiceProvider(
        id: 'google',
        name: 'Google',
        displayName: 'Google',
        category: ServiceCategory.productivity,
        oauthType: AuthKind.oauth2,
        authConfig: const {},
        isEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      );

      final schedulerProvider = ServiceProvider(
        id: 'scheduler',
        name: 'Scheduler',
        displayName: 'Scheduler',
        category: ServiceCategory.automation,
        oauthType: AuthKind.none,
        authConfig: const {},
        isEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now(),
      );

      final slackProvider = ServiceProvider(
        id: 'slack',
        name: 'Slack',
        displayName: 'Slack',
        category: ServiceCategory.communication,
        oauthType: AuthKind.oauth2,
        authConfig: const {},
        isEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      );

      when(
        () => servicesRepository.getAboutInfo(),
      ).thenAnswer((_) async => Right(aboutInfo));

      when(() => servicesRepository.getServicesWithStatus()).thenAnswer(
        (_) async => Right([
          ServiceWithStatus(
            provider: googleProvider,
            isSubscribed: true,
            subscription: UserServiceSubscription(
              id: 'sub-google',
              providerId: 'google',
              status: SubscriptionStatus.active,
              scopeGrants: const [],
              createdAt: DateTime.now().subtract(const Duration(days: 5)),
              updatedAt: DateTime.now(),
            ),
          ),
          ServiceWithStatus(
            provider: schedulerProvider,
            isSubscribed: true,
            subscription: UserServiceSubscription(
              id: 'sub-scheduler',
              providerId: 'scheduler',
              status: SubscriptionStatus.active,
              scopeGrants: const [],
              createdAt: DateTime.now().subtract(const Duration(days: 4)),
              updatedAt: DateTime.now(),
            ),
          ),
          ServiceWithStatus(
            provider: slackProvider,
            isSubscribed: false,
            subscription: null,
          ),
        ]),
      );

      when(() => servicesRepository.getConnectedIdentities()).thenAnswer(
        (_) async => Right([
          ServiceIdentitySummary(
            id: 'identity-google',
            provider: 'google',
            subject: 'user',
            scopes: const ['calendar'],
            connectedAt: DateTime.now().subtract(const Duration(days: 1)),
            expiresAt: DateTime.now().add(const Duration(days: 2)),
          ),
        ]),
      );

      when(() => areaRepository.getAreas()).thenAnswer(
        (_) async => [
          _buildArea(
            id: 'area-1',
            name: 'Morning summary',
            status: AreaStatus.enabled,
          ),
        ],
      );

      final summary = await repository.fetchSummary();

      expect(summary.servicesSummary.connected, 2);
      expect(summary.servicesSummary.totalAvailable, 3);
      expect(summary.servicesSummary.expiringSoon, 1);

      expect(summary.areasSummary.active, 1);
      expect(summary.areasSummary.paused, 0);

      final connectStep = summary.onboardingChecklist.steps.firstWhere(
        (step) => step.id == 'connect-service',
      );
      final createStep = summary.onboardingChecklist.steps.firstWhere(
        (step) => step.id == 'create-area',
      );

      expect(connectStep.isCompleted, isTrue);
      expect(createStep.isCompleted, isTrue);

      expect(summary.alerts.expiringTokens, 1);
      expect(summary.systemStatus.isReachable, isTrue);
      expect(summary.systemStatus.lastPingMs, greaterThan(0));
      expect(summary.nextRuns.length, greaterThanOrEqualTo(1));
      expect(summary.connectedServices, contains('Google'));
      expect(summary.connectedServices, contains('Scheduler'));
      expect(summary.templates, hasLength(1));
      final template = summary.templates.first;
      expect(template.action.componentName, 'timer_interval');
      expect(template.reaction.componentName, 'gmail_send_email');
      expect(template.action.defaultParams['frequencyValue'], 1);
    });

    test('reports offline system when about endpoint fails', () async {
      when(
        () => servicesRepository.getAboutInfo(),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      when(
        () => servicesRepository.getServicesWithStatus(),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => servicesRepository.getConnectedIdentities(),
      ).thenAnswer((_) async => const Right([]));
      when(() => areaRepository.getAreas()).thenAnswer((_) async => <Area>[]);

      final summary = await repository.fetchSummary();

      expect(summary.systemStatus.isReachable, isFalse);
      expect(summary.systemStatus.lastPingMs, equals(-1));
      expect(summary.templates, isEmpty);
      expect(summary.connectedServices, isEmpty);
    });
  });
}

Area _buildArea({
  required String id,
  required String name,
  required AreaStatus status,
}) {
  final providerSummary = ServiceProviderSummary(
    id: 'google',
    name: 'Google',
    displayName: 'Google',
  );

  final actionComponent = ServiceComponent(
    id: 'component-1',
    kind: ComponentKind.action,
    name: 'calendar_event',
    displayName: 'Calendar event',
    description: 'Triggers on new events',
    provider: providerSummary,
    metadata: const {},
    parameters: const [],
  );

  return Area(
    id: id,
    name: name,
    description: 'Test area',
    status: status,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
    action: AreaComponentBinding(
      configId: 'cfg-1',
      componentId: actionComponent.id,
      name: actionComponent.displayName,
      params: const {},
      component: actionComponent,
    ),
    reactions: const [],
  );
}
