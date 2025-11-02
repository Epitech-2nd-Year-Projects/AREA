import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../areas/domain/entities/area.dart';
import '../../../areas/domain/entities/area_history_entry.dart';
import '../../../areas/domain/entities/area_status.dart';
import '../../../areas/domain/repositories/area_repository.dart';
import '../../../services/domain/entities/service_identity_summary.dart';
import '../../../services/domain/entities/service_with_status.dart';
import '../../../services/domain/repositories/services_repository.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_summary_repository.dart';

class DashboardSummaryRepositoryImpl implements DashboardSummaryRepository {
  DashboardSummaryRepositoryImpl({
    required AreaRepository areaRepository,
    required ServicesRepository servicesRepository,
  }) : _areaRepository = areaRepository,
       _servicesRepository = servicesRepository;

  final AreaRepository _areaRepository;
  final ServicesRepository _servicesRepository;

  @override
  Future<DashboardSummary> fetchSummary({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final stopwatch = Stopwatch()..start();

    final aboutEither = await _servicesRepository.getAboutInfo();
    stopwatch.stop();

    String? statusMessage;
    final bool apiReachable = aboutEither.fold((failure) {
      statusMessage = failure.message;
      return false;
    }, (_) => true);
    final int pingMs = apiReachable
        ? max(1, stopwatch.elapsedMilliseconds)
        : -1;

    final servicesResult = await _servicesRepository.getServicesWithStatus();
    final identitiesResult = await _servicesRepository.getConnectedIdentities();

    final List<ServiceWithStatus> servicesWithStatus = servicesResult.fold((
      failure,
    ) {
      _logFailure('servicesWithStatus', failure);
      return <ServiceWithStatus>[];
    }, (services) => services);

    final List<ServiceIdentitySummary> connectedIdentities = identitiesResult
        .fold((failure) {
          _logFailure('connectedIdentities', failure);
          return <ServiceIdentitySummary>[];
        }, (identities) => identities);

    List<Area> areas = [];
    try {
      areas = await _areaRepository.getAreas();
    } catch (error, stackTrace) {
      _logError('getAreas', error, stackTrace);
    }

    final Map<String, ServiceWithStatus> serviceIndex = _buildServiceIndex(
      servicesWithStatus,
    );
    final List<ServiceWithStatus> connectedServices = servicesWithStatus
        .where((service) => service.isSubscribed)
        .toList();

    final int expiringSoonCount = _countIdentitiesExpiringSoon(
      connectedIdentities,
      now,
    );

    final List<DashboardRun> nextRuns = _buildNextRuns(
      areas: areas,
      serviceIndex: serviceIndex,
    );

    List<DashboardActivity> recentActivity = [];
    try {
      recentActivity = await _buildRecentActivity(
        areas: areas,
        serviceIndex: serviceIndex,
      );
    } catch (error, stackTrace) {
      _logError('buildRecentActivity', error, stackTrace);
    }

    final int failuresLast24h = recentActivity.where((activity) {
      final isRecent = activity.completedAt.isAfter(
        now.subtract(const Duration(hours: 24)),
      );
      return !activity.wasSuccessful && isRecent;
    }).length;

    final DashboardOnboardingChecklist onboardingChecklist =
        _buildOnboardingChecklist(
          hasConnectedServices: connectedServices.isNotEmpty,
          hasAreas: areas.isNotEmpty,
          hasActivity: recentActivity.isNotEmpty,
        );

    final List<DashboardTemplate> templates = _buildTemplates(
      connectedServices: connectedServices,
      serviceIndex: serviceIndex,
    );

    final List<String> connectedServiceNames = connectedServices
        .map((service) => service.provider.displayName)
        .toList();

    final DashboardAlerts alerts = DashboardAlerts(
      failingJobs: failuresLast24h,
      expiringTokens: expiringSoonCount,
    );

    return DashboardSummary(
      onboardingChecklist: onboardingChecklist,
      systemStatus: DashboardSystemStatus(
        isReachable: apiReachable,
        lastPingMs: pingMs,
        lastSyncedAt: DateTime.now(),
        message: statusMessage,
      ),
      servicesSummary: DashboardServicesSummary(
        connected: connectedServices.length,
        expiringSoon: expiringSoonCount,
        totalAvailable: servicesWithStatus.length,
      ),
      areasSummary: DashboardAreasSummary(
        active: areas.where((area) => area.status == AreaStatus.enabled).length,
        paused: areas
            .where((area) => area.status == AreaStatus.disabled)
            .length,
        failuresLast24h: failuresLast24h,
      ),
      nextRuns: nextRuns,
      recentActivity: recentActivity,
      alerts: alerts,
      templates: templates,
      connectedServices: connectedServiceNames,
    );
  }

  Map<String, ServiceWithStatus> _buildServiceIndex(
    List<ServiceWithStatus> services,
  ) {
    final Map<String, ServiceWithStatus> index = {};
    for (final service in services) {
      final provider = service.provider;
      index[_normalize(provider.id)] = service;
      index[_normalize(provider.name)] = service;
      index[_normalize(provider.displayName)] = service;
    }
    return index;
  }

  int _countIdentitiesExpiringSoon(
    List<ServiceIdentitySummary> identities,
    DateTime now,
  ) {
    final expiryThreshold = now.add(const Duration(days: 3));
    return identities.where((identity) {
      final expiresAt = identity.expiresAt;
      if (expiresAt == null) {
        return false;
      }
      return expiresAt.isBefore(expiryThreshold);
    }).length;
  }

  DashboardOnboardingChecklist _buildOnboardingChecklist({
    required bool hasConnectedServices,
    required bool hasAreas,
    required bool hasActivity,
  }) {
    final steps = <DashboardChecklistStep>[
      DashboardChecklistStep(
        id: 'connect-service',
        title: 'Connect a service',
        isCompleted: hasConnectedServices,
      ),
      DashboardChecklistStep(
        id: 'create-area',
        title: 'Create an Area',
        isCompleted: hasAreas,
      ),
      DashboardChecklistStep(
        id: 'run-test',
        title: 'Run a test',
        isCompleted: hasActivity,
      ),
    ];

    if (!hasActivity && kDebugMode) {
      return DashboardOnboardingChecklist(
        steps: steps
            .map(
              (step) => step.id == 'run-test'
                  ? step.copyWith(isCompleted: true)
                  : step,
            )
            .toList(),
      );
    }

    return DashboardOnboardingChecklist(steps: steps);
  }

  List<DashboardRun> _buildNextRuns({
    required List<Area> areas,
    required Map<String, ServiceWithStatus> serviceIndex,
  }) {
    final List<DashboardRun> runs = [];
    final now = DateTime.now();

    for (final area in areas.take(3)) {
      final provider = area.action.component.provider;
      final normalizedProviderId = _normalize(provider.id);
      final matchingService = serviceIndex[normalizedProviderId];
      final serviceName =
          matchingService?.provider.displayName ?? provider.displayName;
      final serviceId = matchingService?.provider.id ?? provider.id;

      runs.add(
        DashboardRun(
          id: area.id,
          scheduledAt: now.add(Duration(minutes: 45 * (runs.length + 1))),
          areaName: area.name,
          serviceId: serviceId,
          serviceName: serviceName,
        ),
      );
    }

    if (runs.isEmpty && kDebugMode && areas.isNotEmpty) {
      final sampleAreas = areas.take(3).toList();
      for (var i = 0; i < sampleAreas.length; i++) {
        final area = sampleAreas[i];
        final provider = area.action.component.provider;
        runs.add(
          DashboardRun(
            id: '${area.id}-sample',
            scheduledAt: now.add(Duration(hours: i + 1)),
            areaName: area.name,
            serviceId: provider.id,
            serviceName: provider.displayName,
          ),
        );
      }
    }

    return runs;
  }

  Future<List<DashboardActivity>> _buildRecentActivity({
    required List<Area> areas,
    required Map<String, ServiceWithStatus> serviceIndex,
  }) async {
    final activeAreas = areas
        .where((area) => area.status == AreaStatus.enabled)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (activeAreas.isEmpty) {
      return <DashboardActivity>[];
    }

    final List<_AreaExecutionRecord> records = [];
    for (final area in activeAreas.take(10)) {
      try {
        final history = await _areaRepository.getAreaHistory(
          area.id,
          limit: 5,
        );
        for (final entry in history) {
          records.add(_AreaExecutionRecord(area: area, entry: entry));
        }
      } catch (error, stackTrace) {
        _logError('history:${area.id}', error, stackTrace);
      }
    }

    if (records.isEmpty) {
      return <DashboardActivity>[];
    }

    records.sort(
      (a, b) => b.entry.updatedAt.compareTo(a.entry.updatedAt),
    );

    final List<DashboardActivity> activities = [];
    for (final record in records) {
      if (activities.length >= 5) {
        break;
      }

      activities.add(
        _toDashboardActivity(
          area: record.area,
          entry: record.entry,
          serviceIndex: serviceIndex,
        ),
      );
    }

    return activities;
  }

  DashboardActivity _toDashboardActivity({
    required Area area,
    required AreaHistoryEntry entry,
    required Map<String, ServiceWithStatus> serviceIndex,
  }) {
    final providerKey = _normalize(entry.reactionProvider);
    final matchingService = serviceIndex[providerKey];
    final serviceName =
        matchingService?.provider.displayName ?? entry.reactionProvider;
    final serviceId = matchingService?.provider.id ?? entry.reactionProvider;

    final duration = entry.duration ?? Duration.zero;
    final safeDuration = duration.isNegative ? duration.abs() : duration;

    return DashboardActivity(
      id: '${area.id}:${entry.jobId}',
      areaName: area.name,
      serviceId: serviceId,
      serviceName: serviceName,
      status: entry.status,
      wasSuccessful: entry.isSuccessful,
      duration: safeDuration,
      completedAt: entry.updatedAt.toLocal(),
    );
  }

  List<DashboardTemplate> _buildTemplates({
    required List<ServiceWithStatus> connectedServices,
    required Map<String, ServiceWithStatus> serviceIndex,
  }) {
    final connectedKeys = connectedServices
        .expand<String>(
          (service) => [
            _normalize(service.provider.id),
            _normalize(service.provider.name),
            _normalize(service.provider.displayName),
          ],
        )
        .toSet();

    final matchingDefinitions = _templateCatalog.where(
      (definition) => definition.requiredServices.every(
        (service) => connectedKeys.contains(service),
      ),
    );

    return matchingDefinitions.map((definition) {
      final actionStep = definition.action;
      final reactionStep = definition.reaction;

      final actionService =
          serviceIndex[_normalize(actionStep.providerId)]?.provider;
      final reactionService =
          serviceIndex[_normalize(reactionStep.providerId)]?.provider;

      final primaryServiceName =
          actionService?.displayName ?? actionStep.providerDisplayName;
      final secondaryServiceName =
          reactionService?.displayName ?? reactionStep.providerDisplayName;

      return DashboardTemplate(
        id: definition.id,
        title: definition.title,
        description: definition.description,
        primaryService: primaryServiceName,
        secondaryService: secondaryServiceName,
        suggestedName: definition.suggestedName,
        suggestedDescription: definition.suggestedDescription,
        action: DashboardTemplateStep(
          providerId: actionStep.providerId,
          providerDisplayName: primaryServiceName,
          componentName: actionStep.componentName,
          componentDisplayName: actionStep.componentDisplayName,
          defaultParams: Map<String, dynamic>.from(actionStep.defaultParams),
        ),
        reaction: DashboardTemplateStep(
          providerId: reactionStep.providerId,
          providerDisplayName: secondaryServiceName,
          componentName: reactionStep.componentName,
          componentDisplayName: reactionStep.componentDisplayName,
          defaultParams: Map<String, dynamic>.from(reactionStep.defaultParams),
        ),
      );
    }).toList();
  }

  void _logFailure(String contextLabel, Failure failure) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      'DashboardSummaryRepositoryImpl: $contextLabel failed → ${failure.message}',
    );
  }

  void _logError(String contextLabel, Object error, StackTrace trace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('DashboardSummaryRepositoryImpl: $contextLabel threw $error');
    debugPrint('$trace');
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _AreaExecutionRecord {
  final Area area;
  final AreaHistoryEntry entry;

  _AreaExecutionRecord({required this.area, required this.entry});
}

class _TemplateStepDefinition {
  final String providerId;
  final String providerDisplayName;
  final String componentName;
  final String componentDisplayName;
  final Map<String, dynamic> defaultParams;

  const _TemplateStepDefinition({
    required this.providerId,
    required this.providerDisplayName,
    required this.componentName,
    required this.componentDisplayName,
    required this.defaultParams,
  });
}

class _TemplateDefinition {
  final String id;
  final List<String> requiredServices;
  final String title;
  final String description;
  final String primaryService;
  final String primaryServiceDisplayName;
  final String? secondaryService;
  final String? secondaryServiceDisplayName;
  final String suggestedName;
  final String? suggestedDescription;
  final _TemplateStepDefinition action;
  final _TemplateStepDefinition reaction;

  const _TemplateDefinition({
    required this.id,
    required this.requiredServices,
    required this.title,
    required this.description,
    required this.primaryService,
    required this.primaryServiceDisplayName,
    this.secondaryService,
    this.secondaryServiceDisplayName,
    required this.suggestedName,
    this.suggestedDescription,
    required this.action,
    required this.reaction,
  });
}

const List<_TemplateDefinition> _templateCatalog = [
  _TemplateDefinition(
    id: 'scheduler-gmail-10min-email',
    requiredServices: ['scheduler', 'google'],
    title: 'Send Gmail every minute (debug)',
    description:
        'Trigger a Gmail message every minute using the Scheduler service. Use for testing and adjust frequency afterwards.',
    primaryService: 'scheduler',
    primaryServiceDisplayName: 'Scheduler',
    secondaryService: 'google',
    secondaryServiceDisplayName: 'Gmail',
    suggestedName: 'Email pulse every minute',
    suggestedDescription:
        'Sends a Gmail update to the chosen recipients every minute. Change cadence once validation is complete.',
    action: _TemplateStepDefinition(
      providerId: 'scheduler',
      providerDisplayName: 'Scheduler',
      componentName: 'timer_interval',
      componentDisplayName: 'Recurring timer',
      defaultParams: {'frequencyValue': 1, 'frequencyUnit': 'minutes'},
    ),
    reaction: _TemplateStepDefinition(
      providerId: 'google',
      providerDisplayName: 'Gmail',
      componentName: 'gmail_send_email',
      componentDisplayName: 'Send email with Gmail',
      defaultParams: {
        'subject': 'Quick update (every 10 minutes)',
        'body':
            'Automated message sent every 10 minutes. Update the body to include relevant details.',
        'to': 'recipient@example.com',
      },
    ),
  ),
  _TemplateDefinition(
    id: 'github-stars-gmail-alert',
    requiredServices: ['github', 'google'],
    title: 'Email me when my repo gets a star',
    description:
        'Keep an eye on repository traction by receiving an email for each new GitHub star.',
    primaryService: 'github',
    primaryServiceDisplayName: 'GitHub',
    secondaryService: 'google',
    secondaryServiceDisplayName: 'Gmail',
    suggestedName: 'Celebrate every new GitHub star',
    suggestedDescription:
        'Sends a friendly Gmail notification every time your repository picks up a fresh star.',
    action: _TemplateStepDefinition(
      providerId: 'github',
      providerDisplayName: 'GitHub',
      componentName: 'repo_new_stars',
      componentDisplayName: 'New repository star',
      defaultParams: {
        'owner': 'my-org',
        'repository': 'awesome-project',
        'perPage': 30,
      },
    ),
    reaction: _TemplateStepDefinition(
      providerId: 'google',
      providerDisplayName: 'Gmail',
      componentName: 'gmail_send_email',
      componentDisplayName: 'Send email with Gmail',
      defaultParams: {
        'to': 'alerts@example.com',
        'subject': 'New star on your GitHub repository',
        'body':
            'Good news! Your repository just gained a new star. Review the activity on GitHub and keep the momentum going.',
      },
    ),
  ),
  _TemplateDefinition(
    id: 'github-stars-create-issue',
    requiredServices: ['github'],
    title: 'Create an issue for new GitHub stars',
    description:
        'Track community love by opening a lightweight issue whenever your repository is starred.',
    primaryService: 'github',
    primaryServiceDisplayName: 'GitHub',
    secondaryService: 'github',
    secondaryServiceDisplayName: 'GitHub',
    suggestedName: 'Follow up on new GitHub stars',
    suggestedDescription:
        'Creates a GitHub issue so you can thank the user or review the star later.',
    action: _TemplateStepDefinition(
      providerId: 'github',
      providerDisplayName: 'GitHub',
      componentName: 'repo_new_stars',
      componentDisplayName: 'New repository star',
      defaultParams: {
        'owner': 'my-org',
        'repository': 'awesome-project',
        'perPage': 30,
      },
    ),
    reaction: _TemplateStepDefinition(
      providerId: 'github',
      providerDisplayName: 'GitHub',
      componentName: 'github_create_issue',
      componentDisplayName: 'Create GitHub issue',
      defaultParams: {
        'owner': 'my-org',
        'repository': 'awesome-project',
        'title': 'New GitHub star to follow up',
        'body':
            'A new user starred this repository. Leave a note here to follow up or thank them later.',
        'labels': 'community,stars',
      },
    ),
  ),
  _TemplateDefinition(
    id: 'scheduler-github-weekly-issue',
    requiredServices: ['scheduler', 'github'],
    title: 'Weekly GitHub planning issue',
    description:
        'Open a standing GitHub issue on a weekly cadence to track project priorities.',
    primaryService: 'scheduler',
    primaryServiceDisplayName: 'Scheduler',
    secondaryService: 'github',
    secondaryServiceDisplayName: 'GitHub',
    suggestedName: 'Weekly GitHub planning',
    suggestedDescription:
        "Creates a GitHub issue every Monday morning so you can capture the week's goals.",
    action: _TemplateStepDefinition(
      providerId: 'scheduler',
      providerDisplayName: 'Scheduler',
      componentName: 'timer_interval',
      componentDisplayName: 'Recurring timer',
      defaultParams: {'frequencyValue': 7, 'frequencyUnit': 'days'},
    ),
    reaction: _TemplateStepDefinition(
      providerId: 'github',
      providerDisplayName: 'GitHub',
      componentName: 'github_create_issue',
      componentDisplayName: 'Create GitHub issue',
      defaultParams: {
        'owner': 'my-org',
        'repository': 'awesome-project',
        'title': 'Weekly planning - {{date}}',
        'body':
            'Kick off the week by listing priorities, blockers, and open questions.',
        'labels': 'planning,automation',
      },
    ),
  ),
];
