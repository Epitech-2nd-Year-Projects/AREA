import 'package:area/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:area/features/dashboard/domain/repositories/dashboard_summary_repository.dart';
import 'package:area/features/dashboard/domain/use_cases/get_dashboard_summary.dart';
import 'package:area/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:area/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDashboardSummaryRepository extends Mock
    implements DashboardSummaryRepository {}

void main() {
  late _MockDashboardSummaryRepository repository;
  late DashboardCubit cubit;
  late DashboardSummary summary;
  late DashboardSummary refreshedSummary;

  setUp(() {
    repository = _MockDashboardSummaryRepository();
    cubit = DashboardCubit(GetDashboardSummary(repository));
    final now = DateTime(2024, 01, 01, 9, 30);
    summary = DashboardSummary(
      onboardingChecklist: const DashboardOnboardingChecklist(steps: []),
      systemStatus: DashboardSystemStatus(
        isReachable: true,
        lastPingMs: 12,
        lastSyncedAt: now,
      ),
      servicesSummary: const DashboardServicesSummary(
        connected: 1,
        expiringSoon: 0,
        totalAvailable: 2,
      ),
      areasSummary: const DashboardAreasSummary(
        active: 1,
        paused: 0,
        failuresLast24h: 0,
      ),
      nextRuns: const [],
      recentActivity: const [],
      alerts: const DashboardAlerts(failingJobs: 0, expiringTokens: 0),
      templates: const [],
      connectedServices: const ['Google'],
    );

    refreshedSummary = summary.copyWith(
      servicesSummary: const DashboardServicesSummary(
        connected: 2,
        expiringSoon: 0,
        totalAvailable: 3,
      ),
      connectedServices: const ['Google', 'Scheduler'],
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('emits loading then loaded summary', () async {
    when(
      () => repository.fetchSummary(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => summary);

    expectLater(
      cubit.stream,
      emitsInOrder([
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (state) => state.summary,
          'summary',
          summary,
        ),
      ]),
    );

    await cubit.load();
  });

  test('marks refreshing when reloading without forceRefresh', () async {
    var callCount = 0;
    when(
      () => repository.fetchSummary(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((invocation) async {
      final forceRefresh =
          invocation.namedArguments[#forceRefresh] as bool? ?? false;
      callCount += 1;
      if (forceRefresh || callCount > 1) {
        return refreshedSummary;
      }
      return summary;
    });

    await cubit.load();

    final emittedStates = <DashboardState>[];
    final subscription = cubit.stream.listen(emittedStates.add);

    await cubit.load();

    await subscription.cancel();

    expect(
      emittedStates.first,
      isA<DashboardLoaded>().having(
        (state) => state.isRefreshing,
        'isRefreshing',
        true,
      ),
    );
    expect(
      cubit.state,
      isA<DashboardLoaded>().having(
        (state) => state.summary,
        'summary',
        refreshedSummary,
      ),
    );
  });

  test('emits error when repository throws', () async {
    when(
      () => repository.fetchSummary(forceRefresh: any(named: 'forceRefresh')),
    ).thenThrow(Exception('failure'));

    expectLater(
      cubit.stream,
      emitsInOrder([isA<DashboardLoading>(), isA<DashboardError>()]),
    );

    await cubit.load();
  });
}
