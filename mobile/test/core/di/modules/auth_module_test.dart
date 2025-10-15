import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:area/core/di/modules/auth_module.dart';
import 'package:area/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:area/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:area/features/auth/data/datasources/oauth_remote_datasource.dart';
import 'package:area/features/auth/domain/repositories/auth_repository.dart';
import 'package:area/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:area/core/services/oauth_manager.dart';
import 'package:area/core/network/api_client.dart';
import 'package:area/core/storage/local_prefs_manager.dart';

void main() {
  late GetIt sl;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sl = GetIt.asNewInstance();

    sl.registerSingleton<ApiClient>(ApiClient());
    sl.registerSingleton<LocalPrefsManager>(LocalPrefsManager());
  });

  test('AuthModule register all dependencies', () async {
    final module = AuthModule();
    await module.register(sl);

    expect(sl.isRegistered<AuthRemoteDataSource>(), isTrue);
    expect(sl.isRegistered<AuthLocalDataSource>(), isTrue);
    expect(sl.isRegistered<OAuthRemoteDataSource>(), isTrue);
    expect(sl.isRegistered<AuthRepository>(), isTrue);
    expect(sl.isRegistered<AuthBloc>(), isTrue);
    expect(sl.isRegistered<OAuthManager>(), isTrue);
  });
}