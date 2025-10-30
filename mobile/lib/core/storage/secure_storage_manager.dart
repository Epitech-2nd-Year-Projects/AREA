import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'exceptions/storage_exceptions.dart';

class SecureStorageManager {
  final FlutterSecureStorage _storage;

  SecureStorageManager(FlutterSecureStorage? storage)
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException("Failed to write secure data for key : $key");
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException("Failed to read secure data for key : $key");
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException("Failed to delete secure data for key : $key");
    }
  }
}
