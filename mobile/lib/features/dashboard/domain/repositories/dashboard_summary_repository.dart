import '../entities/dashboard_summary.dart';

/// Contract for fetching aggregated dashboard information.
abstract class DashboardSummaryRepository {
  Future<DashboardSummary> fetchSummary({bool forceRefresh = false});
}
