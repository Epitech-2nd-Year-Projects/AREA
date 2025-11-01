import 'package:dio/dio.dart';
import 'package:area/core/network/api_client.dart';
import 'package:area/core/storage/local_prefs_manager.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _kServerAddressKey = 'server_address';
  static const _kColorBlindModeKey = 'accessibility_color_blind_mode';
  static const _kScreenReaderKey = 'accessibility_screen_reader';

  final LocalPrefsManager _prefs;
  final ApiClient _api;

  SettingsRepositoryImpl(this._prefs, this._api);

  @override
  String getServerAddress() {
    final saved = _prefs.readString(_kServerAddressKey);
    return saved ?? _api.baseUrl;
  }

  @override
  Future<void> setServerAddress(String address) async {
    await _prefs.writeString(_kServerAddressKey, address);
    _api.updateBaseUrl(address);
  }

  @override
  Future<bool> probeServerAddress(String address) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: address,
        connectTimeout: const Duration(milliseconds: 1500),
        receiveTimeout: const Duration(milliseconds: 1500),
        validateStatus: (code) => true,
      ),
    );
    try {
      await dio.get('/');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool getColorBlindMode() {
    return _prefs.readBool(_kColorBlindModeKey, defaultValue: false);
  }

  @override
  Future<void> setColorBlindMode(bool enabled) {
    return _prefs.writeBool(_kColorBlindModeKey, enabled);
  }

  @override
  bool getScreenReaderEnabled() {
    return _prefs.readBool(_kScreenReaderKey, defaultValue: false);
  }

  @override
  Future<void> setScreenReaderEnabled(bool enabled) {
    return _prefs.writeBool(_kScreenReaderKey, enabled);
  }
}
