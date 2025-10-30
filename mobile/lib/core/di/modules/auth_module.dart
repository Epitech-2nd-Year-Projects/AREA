import 'package:get_it/get_it.dart';
import '../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../features/auth/data/datasources/oauth_remote_datasource.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../features/auth/presentation/blocs/auth_bloc.dart';
import '../../services/oauth_manager.dart';
import '../../network/api_client.dart';
import '../../storage/local_prefs_manager.dart';
import '../di_modules.dart';

class AuthModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
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
      final m = OAuthManager();
      m.initialize(sl<AuthRepository>(), sl<OAuthRemoteDataSource>());
      return m;
    });
  }
}
