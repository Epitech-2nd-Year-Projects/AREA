import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:area/core/di/modules/network_module.dart';
import 'package:area/core/network/api_client.dart';
import 'package:area/core/network/api_config.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => '/tmp/test_support';
}

void main() {
  late GetIt sl;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = FakePathProviderPlatform();
    sl = GetIt.asNewInstance();
  });

  test('NetworkModule register ApiClient and ApiConfig', () async {
    final module = NetworkModule();
    await module.register(sl);

    expect(sl.isRegistered<ApiClient>(), isTrue);
    expect(sl.isRegistered<ApiConfig>(), isTrue);
  });
}