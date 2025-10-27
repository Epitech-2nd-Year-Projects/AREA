import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_summary.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final bool isRefreshing;

  const DashboardLoaded({
    required this.summary,
    this.isRefreshing = false,
  });

  DashboardLoaded copyWith({
    DashboardSummary? summary,
    bool? isRefreshing,
  }) {
    return DashboardLoaded(
      summary: summary ?? this.summary,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [summary, isRefreshing];
}

class DashboardError extends DashboardState {
  final String? message;

  const DashboardError([this.message]);

  @override
  List<Object?> get props => [message];
}
