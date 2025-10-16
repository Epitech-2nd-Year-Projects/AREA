import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/storage/secure_storage_manager.dart';
import 'package:area/core/storage/exceptions/storage_exceptions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureStorageManager', () {
    late MockSecureStorage mockStorage;
    late SecureStorageManager manager;

    setUp(() {
      mockStorage = MockSecureStorage();
      manager = SecureStorageManager(mockStorage);
    });

    test('write should call FlutterSecureStorage.write', () async {
      when(() => mockStorage.write(key: 'k', value: 'v'))
          .thenAnswer((_) async => {});

      await manager.write('k', 'v');
      verify(() => mockStorage.write(key: 'k', value: 'v')).called(1);
    });

    test('write should throw StorageException when write fails', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenThrow(Exception('fail'));

      expect(() => manager.write('x', 'y'),
          throwsA(isA<StorageException>().having((e) => e.message, 'message',
              contains('Failed to write secure data'))));
    });

    test('read should return correct value', () async {
      when(() => mockStorage.read(key: 'key')).thenAnswer((_) async => 'value');
      final v = await manager.read('key');
      expect(v, 'value');
    });

    test('read should throw StorageException on failure', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenThrow(Exception('boom'));
      expect(
            () => manager.read('test'),
        throwsA(isA<StorageException>().having(
                (e) => e.message, 'message', contains('Failed to read secure data'))),
      );
    });

    test('delete should call delete successfully', () async {
      when(() => mockStorage.delete(key: 'a')).thenAnswer((_) async => {});
      await manager.delete('a');
      verify(() => mockStorage.delete(key: 'a')).called(1);
    });

    test('delete should throw StorageException when delete fails', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenThrow(Exception('fail'));
      expect(
            () => manager.delete('bad'),
        throwsA(isA<StorageException>().having(
                (e) => e.message, 'message', contains('Failed to delete secure data'))),
      );
    });
  });
}