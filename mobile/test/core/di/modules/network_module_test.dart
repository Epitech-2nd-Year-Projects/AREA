import 'package:area/core/di/modules/network_module.dart';
import 'package:area/core/network/api_client.dart';
import 'package:area/core/network/api_config.dart';
import 'package:area/core/storage/local_prefs_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => '/tmp/test_support';
}

void main() {
  late GetIt sl;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = FakePathProviderPlatform();
    sl = GetIt.asNewInstance();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localPrefs = LocalPrefsManager()..prefsForTest = prefs;
    sl.registerSingleton<LocalPrefsManager>(localPrefs);
  });

  test('NetworkModule register ApiClient and ApiConfig', () async {
    final module = NetworkModule();
    await module.register(sl);

    expect(sl.isRegistered<ApiClient>(), isTrue);
    expect(sl.isRegistered<ApiConfig>(), isTrue);
  });
}
