import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:area/core/di/modules/services_module.dart';
import 'package:area/core/network/api_client.dart';
import 'package:area/features/services/data/datasources/services_remote_datasource.dart';
import 'package:area/features/services/domain/repositories/services_repository.dart';

void main() {
  late GetIt sl;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sl = GetIt.asNewInstance();

    sl.registerSingleton<ApiClient>(ApiClient());
  });

  test('ServicesModule register his dependencies', () async {
    final module = ServicesModule();
    await module.register(sl);

    expect(sl.isRegistered<ServicesRemoteDataSource>(), isTrue);
    expect(sl.isRegistered<ServicesRepository>(), isTrue);
  });
}