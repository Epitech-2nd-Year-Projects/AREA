import 'package:area/features/areas/domain/entities/area.dart';
import 'package:area/features/areas/domain/entities/area_component_binding.dart';
import 'package:area/features/areas/domain/entities/area_status.dart';
import 'package:area/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:area/features/services/domain/entities/component_parameter.dart';
import 'package:area/features/services/domain/entities/service_component.dart';
import 'package:area/features/services/domain/entities/service_provider.dart';
import 'package:area/features/services/domain/entities/service_provider_summary.dart';
import 'package:area/features/services/domain/entities/service_with_status.dart';
import 'package:area/features/services/domain/entities/user_service_subscription.dart';
import 'package:area/features/services/domain/value_objects/auth_kind.dart';
import 'package:area/features/services/domain/value_objects/component_kind.dart';
import 'package:area/features/services/domain/value_objects/service_category.dart';
import 'package:area/features/services/domain/value_objects/subscription_status.dart';
import 'package:area/features/profile/presentation/cubits/profile_state.dart';
import 'package:area/features/auth/domain/entities/user.dart';

ServiceProvider buildServiceProvider({
  String id = 'service-1',
  String name = 'service_name',
  String displayName = 'Service Name',
  ServiceCategory category = ServiceCategory.productivity,
  AuthKind authKind = AuthKind.oauth2,
  bool isEnabled = true,
}) {
  final now = DateTime(2024, 1, 1);
  return ServiceProvider(
    id: id,
    name: name,
    displayName: displayName,
    category: category,
    oauthType: authKind,
    authConfig: const {},
    isEnabled: isEnabled,
    createdAt: now,
    updatedAt: now,
  );
}

ServiceWithStatus buildServiceWithStatus({
  ServiceProvider? provider,
  bool isSubscribed = false,
  UserServiceSubscription? subscription,
}) {
  final resolvedProvider = provider ?? buildServiceProvider();
  return ServiceWithStatus(
    provider: resolvedProvider,
    isSubscribed: isSubscribed,
    subscription: subscription,
  );
}

UserServiceSubscription buildSubscription({
  String id = 'sub-1',
  String providerId = 'service-1',
  SubscriptionStatus status = SubscriptionStatus.active,
  String? identityId = 'identity-1',
}) {
  final now = DateTime(2024, 1, 1);
  return UserServiceSubscription(
    id: id,
    providerId: providerId,
    status: status,
    scopeGrants: const ['basic'],
    createdAt: now,
    updatedAt: now,
    userId: 'user-1',
    identityId: identityId,
  );
}

ServiceComponent buildServiceComponent({
  String id = 'component-1',
  ComponentKind kind = ComponentKind.action,
  String name = 'component',
  String displayName = 'Component Display',
  String? description = 'Description',
  ServiceProviderSummary? provider,
  List<ComponentParameter> parameters = const [],
}) {
  return ServiceComponent(
    id: id,
    kind: kind,
    name: name,
    displayName: displayName,
    description: description,
    provider: provider ??
        const ServiceProviderSummary(
          id: 'service-1',
          name: 'service',
          displayName: 'Service',
        ),
    metadata: const {},
    parameters: parameters,
  );
}

ComponentParameter buildComponentParameter({
  String key = 'field',
  String label = 'Field',
  bool required = true,
  List<ComponentParameterOption> options = const [],
}) {
  return ComponentParameter(
    key: key,
    label: label,
    required: required,
    type: 'text',
    options: options,
    description: 'Sample description',
  );
}

DashboardOnboardingChecklist buildChecklist({
  List<DashboardChecklistStep>? steps,
}) {
  return DashboardOnboardingChecklist(
    steps: steps ??
        const [
          DashboardChecklistStep(
            id: 'connect-service',
            title: 'Connect a service',
            description: 'Connect your first service',
            isCompleted: false,
          ),
          DashboardChecklistStep(
            id: 'create-area',
            title: 'Create an automation',
            description: 'Create an AREA automation',
            isCompleted: true,
          ),
        ],
  );
}

DashboardServicesSummary buildServicesSummary({
  int connected = 3,
  int expiringSoon = 1,
  int totalAvailable = 12,
}) {
  return DashboardServicesSummary(
    connected: connected,
    expiringSoon: expiringSoon,
    totalAvailable: totalAvailable,
  );
}

DashboardAreasSummary buildAreasSummary({
  int active = 5,
  int paused = 1,
  int failuresLast24h = 0,
}) {
  return DashboardAreasSummary(
    active: active,
    paused: paused,
    failuresLast24h: failuresLast24h,
  );
}

DashboardSystemStatus buildSystemStatus({
  bool isReachable = true,
  int lastPingMs = 120,
  DateTime? lastSyncedAt,
  String? message,
}) {
  return DashboardSystemStatus(
    isReachable: isReachable,
    lastPingMs: lastPingMs,
    lastSyncedAt: lastSyncedAt ?? DateTime(2024, 1, 1, 12),
    message: message,
  );
}

Area buildArea({
  String id = 'area-1',
  String name = 'Weekly digest',
  String description = 'Send me a weekly digest',
  AreaStatus status = AreaStatus.enabled,
  AreaComponentBinding? action,
  List<AreaComponentBinding>? reactions,
}) {
  final now = DateTime(2024, 1, 1);
  final resolvedAction = action ??
      AreaComponentBinding(
        configId: 'config-action',
        componentId: 'component-action',
        name: 'When a new email arrives',
        params: const {'label': 'Inbox'},
        component: buildServiceComponent(
          id: 'action-component',
          displayName: 'New Email',
          kind: ComponentKind.action,
        ),
      );
  final resolvedReactions = reactions ??
      [
        AreaComponentBinding(
          configId: 'config-reaction',
          componentId: 'component-reaction',
          name: 'Create a task',
          params: const {'list': 'Personal'},
          component: buildServiceComponent(
            id: 'reaction-component',
            displayName: 'Create Task',
            kind: ComponentKind.reaction,
          ),
        ),
      ];

  return Area(
    id: id,
    name: name,
    description: description,
    status: status,
    createdAt: now,
    updatedAt: now,
    action: resolvedAction,
    reactions: resolvedReactions,
  );
}

ProfileLoaded buildProfileLoadedState({
  String displayName = 'Alex',
  String email = 'alex@example.com',
  List<ServiceWithStatus>? services,
}) {
  return ProfileLoaded(
    user: User(id: 'user-1', email: email),
    displayName: displayName,
    services: services ?? [buildServiceWithStatus(isSubscribed: true)],
  );
}

DashboardTemplate buildDashboardTemplate({
  String id = 'template-1',
  String title = 'Sync calendar to tasks',
  String description = 'Create a task every time a calendar event is created.',
  String primaryService = 'Google Calendar',
  String? secondaryService = 'Notion',
}) {
  return DashboardTemplate(
    id: id,
    title: title,
    description: description,
    primaryService: primaryService,
    secondaryService: secondaryService,
    suggestedName: 'Calendar to Tasks',
    suggestedDescription: 'Automate event to task creation',
    action: const DashboardTemplateStep(
      providerId: 'calendar',
      providerDisplayName: 'Google Calendar',
      componentName: 'new_event',
      componentDisplayName: 'New Event',
      defaultParams: {'calendar': 'primary'},
    ),
    reaction: const DashboardTemplateStep(
      providerId: 'todo',
      providerDisplayName: 'Notion',
      componentName: 'create_task',
      componentDisplayName: 'Create Task',
      defaultParams: {'database': 'Tasks'},
    ),
  );
}
