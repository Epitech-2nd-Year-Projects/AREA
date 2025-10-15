import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:area/core/di/modules/core_module.dart';
import 'package:area/core/storage/cache_manager.dart';
import 'package:area/core/storage/local_prefs_manager.dart';
import 'package:area/core/storage/secure_storage_manager.dart';

void main() {
  late GetIt sl;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    SharedPreferences.setMockInitialValues({});

    sl = GetIt.asNewInstance();
  });

  test('CoreModule register his dependencies', () async {
    final module = CoreModule();
    await module.register(sl);

    expect(sl.isRegistered<SecureStorageManager>(), isTrue);
    expect(sl.isRegistered<LocalPrefsManager>(), isTrue);
    expect(sl.isRegistered<CacheManager>(), isTrue);
  });
}