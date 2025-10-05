abstract class SettingsRepository {
  String getServerAddress();
  Future<void> setServerAddress(String address);
  Future<bool> probeServerAddress(String address);
}
