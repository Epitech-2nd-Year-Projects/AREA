import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:area/core/di/modules/settings_module.dart';
import 'package:area/core/network/api_client.dart';
import 'package:area/core/storage/local_prefs_manager.dart';
import 'package:area/features/settings/domain/repositories/settings_repository.dart';
import 'package:area/features/settings/data/repositories/settings_repository_impl.dart';

void main() {
  late GetIt sl;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sl = GetIt.asNewInstance();

    sl.registerSingleton<ApiClient>(ApiClient());
    final prefs = LocalPrefsManager();
    await prefs.init();
    sl.registerSingleton<LocalPrefsManager>(prefs);
  });

  test('SettingsModule register SettingsRepository', () async {
    final module = SettingsModule();
    await module.register(sl);

    expect(sl.isRegistered<SettingsRepository>(), isTrue);
    final repo = sl<SettingsRepository>();
    expect(repo, isA<SettingsRepositoryImpl>());
  });
}