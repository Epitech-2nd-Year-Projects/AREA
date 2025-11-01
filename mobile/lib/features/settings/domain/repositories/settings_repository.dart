abstract class SettingsRepository {
  String getServerAddress();
  Future<void> setServerAddress(String address);
  Future<bool> probeServerAddress(String address);
  bool getColorBlindMode();
  Future<void> setColorBlindMode(bool enabled);
  bool getScreenReaderEnabled();
  Future<void> setScreenReaderEnabled(bool enabled);
}
