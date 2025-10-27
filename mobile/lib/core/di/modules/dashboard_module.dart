import 'package:get_it/get_it.dart';

import '../../../features/areas/domain/repositories/area_repository.dart';
import '../../../features/dashboard/data/repositories/dashboard_summary_repository_impl.dart';
import '../../../features/dashboard/domain/repositories/dashboard_summary_repository.dart';
import '../../../features/services/domain/repositories/services_repository.dart';
import '../di_modules.dart';

class DashboardModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
    sl.registerLazySingleton<DashboardSummaryRepository>(
      () => DashboardSummaryRepositoryImpl(
        areaRepository: sl<AreaRepository>(),
        servicesRepository: sl<ServicesRepository>(),
      ),
    );
  }
}
