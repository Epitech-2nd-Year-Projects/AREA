import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import '../../network/api_client.dart';
import '../../network/api_config.dart';
import '../di_modules.dart';

class NetworkModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
    final supportDir = await getApplicationSupportDirectory();

    sl.registerLazySingleton<ApiClient>(
            () => ApiClient(cookieDirPath: '${supportDir.path}/cookies'));
    sl.registerLazySingleton<ApiConfig>(() => ApiConfig());
  }
}