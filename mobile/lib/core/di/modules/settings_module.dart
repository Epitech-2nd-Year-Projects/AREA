import 'package:get_it/get_it.dart';
import '../../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../../features/settings/domain/repositories/settings_repository.dart';
import '../../../features/settings/domain/use_cases/get_color_blind_mode.dart';
import '../../../features/settings/domain/use_cases/get_screen_reader_enabled.dart';
import '../../../features/settings/domain/use_cases/set_color_blind_mode.dart';
import '../../../features/settings/domain/use_cases/set_screen_reader_enabled.dart';
import '../../accessibility/accessibility_controller.dart';
import '../../network/api_client.dart';
import '../../storage/local_prefs_manager.dart';
import '../di_modules.dart';
import '../../accessibility/text_to_speech_service.dart';

class SettingsModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
    sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl<LocalPrefsManager>(), sl<ApiClient>()),
    );

    sl.registerLazySingleton<TextToSpeechService>(TextToSpeechService.new);

    sl.registerLazySingleton<AccessibilityController>(
      () => AccessibilityController(
        getColorBlindMode: GetColorBlindMode(sl<SettingsRepository>()),
        setColorBlindMode: SetColorBlindMode(sl<SettingsRepository>()),
        getScreenReaderEnabled: GetScreenReaderEnabled(sl<SettingsRepository>()),
        setScreenReaderEnabled: SetScreenReaderEnabled(sl<SettingsRepository>()),
        textToSpeechService: sl<TextToSpeechService>(),
      ),
    );
  }
}
