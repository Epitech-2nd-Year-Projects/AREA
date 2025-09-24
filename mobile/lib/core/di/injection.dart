import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_manager.dart';
import '../storage/local_prefs_manager.dart';
import '../storage/cache_manager.dart';

final sl = GetIt.instance;

Future<void> initCoreDependencies() async {
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  sl.registerLazySingleton<SecureStorageManager>(() => SecureStorageManager(null));

  final prefs = LocalPrefsManager();
  await prefs.init();
  sl.registerLazySingleton<LocalPrefsManager>(() => prefs);

  sl.registerLazySingleton<CacheManager>(() => CacheManager());
}