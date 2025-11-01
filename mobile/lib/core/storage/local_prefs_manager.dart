import 'package:shared_preferences/shared_preferences.dart';
import 'exceptions/storage_exceptions.dart';

class LocalPrefsManager {
  SharedPreferences? _prefs;

  set prefsForTest(SharedPreferences prefs) => _prefs = prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> writeString(String key, String value) async {
    try {
      await _prefs?.setString(key, value);
    } catch (e) {
      throw StorageException("Failed to write pref for $key");
    }
  }

  String? readString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (e) {
      throw StorageException("Failed to read pref for $key");
    }
  }

  Future<void> writeBool(String key, bool value) async {
    try {
      await _prefs?.setBool(key, value);
    } catch (e) {
      throw StorageException("Failed to write pref for $key");
    }
  }

  bool readBool(String key, {bool defaultValue = false}) {
    try {
      return _prefs?.getBool(key) ?? defaultValue;
    } catch (e) {
      throw StorageException("Failed to read pref for $key");
    }
  }

  Future<void> delete(String key) async {
    try {
      await _prefs?.remove(key);
    } catch (e) {
      throw StorageException("Failed to delete pref for $key");
    }
  }
}
