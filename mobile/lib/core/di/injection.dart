import 'package:area/features/areas/data/repositories/area_repository_impl.dart';
import 'package:area/features/areas/domain/repositories/area_repository.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/services/data/datasources/services_remote_datasource.dart';
import '../network/api_client.dart';
import 'package:path_provider/path_provider.dart';
import '../storage/secure_storage_manager.dart';
import '../storage/local_prefs_manager.dart';
import '../storage/cache_manager.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/services/data/repositories/services_repository_impl.dart';
import '../../features/services/domain/repositories/services_repository.dart';

final sl = GetIt.instance;

Future<void> initCoreDependencies() async {
  final supportDir = await getApplicationSupportDirectory();
  sl.registerLazySingleton<ApiClient>(() => ApiClient(cookieDirPath: '${supportDir.path}/cookies'));

  sl.registerLazySingleton<SecureStorageManager>(() => SecureStorageManager(null));

  final prefs = LocalPrefsManager();
  await prefs.init();
  sl.registerLazySingleton<LocalPrefsManager>(() => prefs);

  sl.registerLazySingleton<CacheManager>(() => CacheManager());

  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl<ApiClient>()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(sl<LocalPrefsManager>()),
  );

  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<AuthRemoteDataSource>(),
                sl<AuthLocalDataSource>(),),
  );
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));

  sl.registerLazySingleton<AreaRepository>(() => AreaRepositoryImpl());

  sl.registerLazySingleton<ServicesRemoteDataSource>(
        () => ServicesRemoteDataSourceImpl(sl<ApiClient>()),
  );

  sl.registerLazySingleton<ServicesRepository>(
        () => ServicesRepositoryImpl(sl<ServicesRemoteDataSource>()),
  );
}
