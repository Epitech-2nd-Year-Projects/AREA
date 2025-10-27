import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_summary_repository.dart';

class GetDashboardSummary {
  final DashboardSummaryRepository repository;

  const GetDashboardSummary(this.repository);

  Future<DashboardSummary> call({bool forceRefresh = false}) {
    return repository.fetchSummary(forceRefresh: forceRefresh);
  }
}
