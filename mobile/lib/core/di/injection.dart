import 'package:area/features/areas/data/repositories/area_repository_impl.dart';
import 'package:area/features/areas/domain/repositories/area_repository.dart';
import 'package:get_it/get_it.dart';
import '../../features/areas/data/datasources/area_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/oauth_remote_datasource.dart';
import '../../features/services/data/datasources/services_remote_datasource.dart';
import '../network/api_client.dart';
import 'package:path_provider/path_provider.dart';
import '../storage/secure_storage_manager.dart';
import '../storage/local_prefs_manager.dart';
import '../storage/cache_manager.dart';
import '../services/oauth_manager.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../features/services/data/repositories/services_repository_impl.dart';
import '../../features/services/domain/repositories/services_repository.dart';
import 'package:area/features/settings/domain/repositories/settings_repository.dart';
import 'package:area/features/settings/data/repositories/settings_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initCoreDependencies() async {
  final supportDir = await getApplicationSupportDirectory();
  sl.registerLazySingleton<ApiClient>(
          () => ApiClient(cookieDirPath: '${supportDir.path}/cookies'));

  sl.registerLazySingleton<SecureStorageManager>(
          () => SecureStorageManager(null));

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

  sl.registerLazySingleton<OAuthRemoteDataSource>(
        () => OAuthRemoteDataSourceImpl(sl<ApiClient>()),
  );

  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      sl<AuthRemoteDataSource>(),
      sl<AuthLocalDataSource>(),
      sl<OAuthRemoteDataSource>(),
    ),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRepository>()));

  sl.registerLazySingleton<OAuthManager>(() {
    final oauthManager = OAuthManager();
    oauthManager.initialize(
      sl<AuthRepository>(),
      sl<OAuthRemoteDataSource>(),
    );
    return oauthManager;
  });

  sl.registerLazySingleton<AreaRemoteDataSource>(
        () => AreaRemoteDataSourceImpl(sl<ApiClient>()),
  );

  sl.registerLazySingleton<AreaRepository>(
        () => AreaRepositoryImpl(sl<AreaRemoteDataSource>()),
  );

  sl.registerLazySingleton<ServicesRemoteDataSource>(
        () => ServicesRemoteDataSourceImpl(sl<ApiClient>()),
  );

  sl.registerLazySingleton<ServicesRepository>(
        () => ServicesRepositoryImpl(sl<ServicesRemoteDataSource>()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<LocalPrefsManager>(), sl<ApiClient>()),
  );
}
