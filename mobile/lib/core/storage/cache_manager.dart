import 'exceptions/storage_exceptions.dart';

class CacheManager {
  final Map<String, dynamic> _cache = {};

  void write(String key, dynamic value) {
    try {
      _cache[key] = value;
    } catch (e) {
      throw StorageException("Failed to cache data for $key");
    }
  }

  T? read<T>(String key) {
    try {
      return _cache[key] as T?;
    } catch (e) {
      throw StorageException("Failed to read cache for $key");
    }
  }

  void delete(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}
