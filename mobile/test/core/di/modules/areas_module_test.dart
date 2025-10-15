import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:area/core/di/modules/areas_module.dart';
import 'package:area/core/network/api_client.dart';
import 'package:area/features/areas/data/datasources/area_remote_datasource.dart';
import 'package:area/features/areas/domain/repositories/area_repository.dart';

void main() {
  late GetIt sl;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sl = GetIt.asNewInstance();

    sl.registerSingleton<ApiClient>(ApiClient());
  });

  test('AreasModule register his dependencies', () async {
    final module = AreasModule();
    await module.register(sl);

    expect(sl.isRegistered<AreaRemoteDataSource>(), isTrue);
    expect(sl.isRegistered<AreaRepository>(), isTrue);
  });
}