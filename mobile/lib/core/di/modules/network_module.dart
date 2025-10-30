import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import '../../network/api_client.dart';
import '../../network/api_config.dart';
import '../../storage/local_prefs_manager.dart';
import '../di_modules.dart';

class NetworkModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
    final supportDir = await getApplicationSupportDirectory();
    final prefs = sl<LocalPrefsManager>();
    final savedBaseUrl = prefs.readString('server_address');
    final url = savedBaseUrl ?? ApiConfig.baseUrl;

    sl.registerLazySingleton<ApiClient>(
      () =>
          ApiClient(baseUrl: url, cookieDirPath: '${supportDir.path}/cookies'),
    );
    sl.registerLazySingleton<ApiConfig>(() => ApiConfig());
  }
}
