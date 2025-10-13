import 'package:get_it/get_it.dart';
import '../../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../../features/settings/domain/repositories/settings_repository.dart';
import '../../storage/local_prefs_manager.dart';
import '../../network/api_client.dart';
import '../di_modules.dart';

class SettingsModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
    sl.registerLazySingleton<SettingsRepository>(
          () => SettingsRepositoryImpl(sl<LocalPrefsManager>(), sl<ApiClient>()),
    );
  }
}