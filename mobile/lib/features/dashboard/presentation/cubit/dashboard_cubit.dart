import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/use_cases/get_dashboard_summary.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(GetDashboardSummary getDashboardSummary)
    : _getDashboardSummary = getDashboardSummary,
      super(const DashboardInitial());

  final GetDashboardSummary _getDashboardSummary;

  Future<void> load({bool forceRefresh = false}) async {
    final currentState = state;
    if (currentState is DashboardLoaded && !forceRefresh) {
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const DashboardLoading());
    }

    try {
      final summary = await _getDashboardSummary(forceRefresh: forceRefresh);
      emit(DashboardLoaded(summary: summary));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('DashboardCubit.load failed: $error');
        debugPrint('$stackTrace');
      }
      emit(const DashboardError());
    }
  }

  Future<void> refresh() => load(forceRefresh: true);
}
