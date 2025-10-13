import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import '../../storage/cache_manager.dart';
import '../../storage/local_prefs_manager.dart';
import '../../storage/secure_storage_manager.dart';
import '../di_modules.dart';

class CoreModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {

    sl.registerLazySingleton<SecureStorageManager>(
          () => SecureStorageManager(null),
    );

    final prefs = LocalPrefsManager();
    await prefs.init();
    sl.registerLazySingleton<LocalPrefsManager>(() => prefs);

    sl.registerLazySingleton<CacheManager>(() => CacheManager());
  }
}