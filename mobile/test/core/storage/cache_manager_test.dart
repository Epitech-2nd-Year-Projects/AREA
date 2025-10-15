import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/storage/cache_manager.dart';
import 'package:area/core/storage/exceptions/storage_exceptions.dart';

class FaultyCacheManager extends CacheManager {
  @override
  void write(String key, dynamic value) {
    try {
      throw Exception('Simulated write failure');
    } catch (e) {
      throw StorageException("Failed to cache data for $key");
    }
  }
}

void main() {
  group('CacheManager', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager();
    });

    test('should write and read values correctly', () {
      cache.write('token', '123');
      final result = cache.read<String>('token');
      expect(result, '123');
    });

    test('should delete specific keys', () {
      cache.write('x', 10);
      cache.delete('x');
      expect(cache.read<int>('x'), isNull);
    });

    test('should clear all entries', () {
      cache.write('a', 1);
      cache.write('b', 2);
      cache.clear();
      expect(cache.read('a'), isNull);
      expect(cache.read('b'), isNull);
    });

    test('should throw on type mismatch', () {
      cache.write('test', 'text');
      expect(
            () => cache.read<int>('test'),
        throwsA(isA<StorageException>().having(
              (e) => e.message,
          'message',
          contains('Failed to read cache for test'),
        )),
      );
    });

    test('should throw StorageException when internal write fails', () {
      final faulty = FaultyCacheManager();
      expect(
            () => faulty.write('key', 'value'),
        throwsA(isA<StorageException>().having(
              (e) => e.message,
          'message',
          contains('Failed to cache data for key'),
        )),
      );
    });
  });
}