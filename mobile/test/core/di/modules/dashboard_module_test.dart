import 'package:area/core/di/modules/dashboard_module.dart';
import 'package:area/features/areas/domain/repositories/area_repository.dart';
import 'package:area/features/dashboard/domain/repositories/dashboard_summary_repository.dart';
import 'package:area/features/services/domain/repositories/services_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockAreaRepository extends Mock implements AreaRepository {}

class _MockServicesRepository extends Mock implements ServicesRepository {}

void main() {
  late GetIt sl;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sl = GetIt.asNewInstance();
    sl.registerSingleton<AreaRepository>(_MockAreaRepository());
    sl.registerSingleton<ServicesRepository>(_MockServicesRepository());
  });

  test('DashboardModule registers dashboard repository', () async {
    final module = DashboardModule();
    await module.register(sl);

    expect(sl.isRegistered<DashboardSummaryRepository>(), isTrue);
  });
}
