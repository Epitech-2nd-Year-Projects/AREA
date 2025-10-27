import 'package:equatable/equatable.dart';

/// Aggregated view model powering the dashboard screen.
class DashboardSummary extends Equatable {
  final DashboardOnboardingChecklist onboardingChecklist;
  final DashboardSystemStatus systemStatus;
  final DashboardServicesSummary servicesSummary;
  final DashboardAreasSummary areasSummary;
  final List<DashboardRun> nextRuns;
  final List<DashboardActivity> recentActivity;
  final DashboardAlerts alerts;
  final List<DashboardTemplate> templates;
  final List<String> connectedServices;

  const DashboardSummary({
    required this.onboardingChecklist,
    required this.systemStatus,
    required this.servicesSummary,
    required this.areasSummary,
    required this.nextRuns,
    required this.recentActivity,
    required this.alerts,
    required this.templates,
    required this.connectedServices,
  });

  DashboardSummary copyWith({
    DashboardOnboardingChecklist? onboardingChecklist,
    DashboardSystemStatus? systemStatus,
    DashboardServicesSummary? servicesSummary,
    DashboardAreasSummary? areasSummary,
    List<DashboardRun>? nextRuns,
    List<DashboardActivity>? recentActivity,
    DashboardAlerts? alerts,
    List<DashboardTemplate>? templates,
    List<String>? connectedServices,
  }) {
    return DashboardSummary(
      onboardingChecklist: onboardingChecklist ?? this.onboardingChecklist,
      systemStatus: systemStatus ?? this.systemStatus,
      servicesSummary: servicesSummary ?? this.servicesSummary,
      areasSummary: areasSummary ?? this.areasSummary,
      nextRuns: nextRuns ?? this.nextRuns,
      recentActivity: recentActivity ?? this.recentActivity,
      alerts: alerts ?? this.alerts,
      templates: templates ?? this.templates,
      connectedServices: connectedServices ?? this.connectedServices,
    );
  }

  @override
  List<Object?> get props => [
    onboardingChecklist,
    systemStatus,
    servicesSummary,
    areasSummary,
    nextRuns,
    recentActivity,
    alerts,
    templates,
    connectedServices,
  ];
}

class DashboardOnboardingChecklist extends Equatable {
  final List<DashboardChecklistStep> steps;

  const DashboardOnboardingChecklist({required this.steps});

  bool get isComplete => steps.every((step) => step.isCompleted);

  @override
  List<Object?> get props => [steps];
}

class DashboardChecklistStep extends Equatable {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;

  const DashboardChecklistStep({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
  });

  DashboardChecklistStep copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return DashboardChecklistStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [id, title, description, isCompleted];
}

class DashboardSystemStatus extends Equatable {
  final bool isReachable;
  final int lastPingMs;
  final DateTime lastSyncedAt;
  final String? message;

  const DashboardSystemStatus({
    required this.isReachable,
    required this.lastPingMs,
    required this.lastSyncedAt,
    this.message,
  });

  DashboardSystemStatus copyWith({
    bool? isReachable,
    int? lastPingMs,
    DateTime? lastSyncedAt,
    String? message,
  }) {
    return DashboardSystemStatus(
      isReachable: isReachable ?? this.isReachable,
      lastPingMs: lastPingMs ?? this.lastPingMs,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [isReachable, lastPingMs, lastSyncedAt, message];
}

class DashboardServicesSummary extends Equatable {
  final int connected;
  final int expiringSoon;
  final int totalAvailable;

  const DashboardServicesSummary({
    required this.connected,
    required this.expiringSoon,
    required this.totalAvailable,
  });

  DashboardServicesSummary copyWith({
    int? connected,
    int? expiringSoon,
    int? totalAvailable,
  }) {
    return DashboardServicesSummary(
      connected: connected ?? this.connected,
      expiringSoon: expiringSoon ?? this.expiringSoon,
      totalAvailable: totalAvailable ?? this.totalAvailable,
    );
  }

  @override
  List<Object?> get props => [connected, expiringSoon, totalAvailable];
}

class DashboardAreasSummary extends Equatable {
  final int active;
  final int paused;
  final int failuresLast24h;

  const DashboardAreasSummary({
    required this.active,
    required this.paused,
    required this.failuresLast24h,
  });

  DashboardAreasSummary copyWith({
    int? active,
    int? paused,
    int? failuresLast24h,
  }) {
    return DashboardAreasSummary(
      active: active ?? this.active,
      paused: paused ?? this.paused,
      failuresLast24h: failuresLast24h ?? this.failuresLast24h,
    );
  }

  @override
  List<Object?> get props => [active, paused, failuresLast24h];
}

class DashboardRun extends Equatable {
  final String id;
  final DateTime scheduledAt;
  final String areaName;
  final String serviceId;
  final String serviceName;

  const DashboardRun({
    required this.id,
    required this.scheduledAt,
    required this.areaName,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  List<Object?> get props => [
    id,
    scheduledAt,
    areaName,
    serviceId,
    serviceName,
  ];
}

class DashboardActivity extends Equatable {
  final String id;
  final String areaName;
  final String serviceId;
  final String serviceName;
  final bool wasSuccessful;
  final Duration duration;
  final DateTime completedAt;

  const DashboardActivity({
    required this.id,
    required this.areaName,
    required this.serviceId,
    required this.serviceName,
    required this.wasSuccessful,
    required this.duration,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [
    id,
    areaName,
    serviceId,
    serviceName,
    wasSuccessful,
    duration,
    completedAt,
  ];
}

class DashboardAlerts extends Equatable {
  final int failingJobs;
  final int expiringTokens;

  const DashboardAlerts({
    required this.failingJobs,
    required this.expiringTokens,
  });

  bool get hasAlerts => failingJobs > 0 || expiringTokens > 0;

  @override
  List<Object?> get props => [failingJobs, expiringTokens];
}

class DashboardTemplateStep extends Equatable {
  final String providerId;
  final String providerDisplayName;
  final String componentName;
  final String componentDisplayName;
  final Map<String, dynamic> defaultParams;

  const DashboardTemplateStep({
    required this.providerId,
    required this.providerDisplayName,
    required this.componentName,
    required this.componentDisplayName,
    required this.defaultParams,
  });

  @override
  List<Object?> get props => [
    providerId,
    providerDisplayName,
    componentName,
    componentDisplayName,
    defaultParams,
  ];
}

class DashboardTemplate extends Equatable {
  final String id;
  final String title;
  final String description;
  final String primaryService;
  final String? secondaryService;
  final String suggestedName;
  final String? suggestedDescription;
  final DashboardTemplateStep action;
  final DashboardTemplateStep reaction;

  const DashboardTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.primaryService,
    this.secondaryService,
    required this.suggestedName,
    this.suggestedDescription,
    required this.action,
    required this.reaction,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    primaryService,
    secondaryService,
    suggestedName,
    suggestedDescription,
    action,
    reaction,
  ];
}
