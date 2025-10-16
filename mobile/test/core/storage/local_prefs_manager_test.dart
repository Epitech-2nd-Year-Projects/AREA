import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/storage/local_prefs_manager.dart';
import 'package:area/core/storage/exceptions/storage_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('LocalPrefsManager', () {
    late LocalPrefsManager manager;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      manager = LocalPrefsManager();
      manager.prefsForTest = mockPrefs;
    });

    test('init should assign SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final m = LocalPrefsManager();
      await m.init();
      expect(m.readString('unknown'), isNull);
    });

    test('writeString should call setString successfully', () async {
      when(() => mockPrefs.setString('key', 'value'))
          .thenAnswer((_) async => true);

      await manager.writeString('key', 'value');

      verify(() => mockPrefs.setString('key', 'value')).called(1);
    });

    test('writeString should throw StorageException on failure', () async {
      when(() => mockPrefs.setString(any(), any()))
          .thenThrow(Exception('fail'));
      expect(() async => manager.writeString('x', 'y'),
          throwsA(isA<StorageException>()));
    });

    test('readString should return stored value', () {
      when(() => mockPrefs.getString('token')).thenReturn('abc');
      final v = manager.readString('token');
      expect(v, 'abc');
    });

    test('readString should throw StorageException on error', () {
      when(() => mockPrefs.getString(any())).thenThrow(Exception('error'));
      expect(() => manager.readString('bad'),
          throwsA(isA<StorageException>()));
    });

    test('delete should call remove successfully', () async {
      when(() => mockPrefs.remove('a')).thenAnswer((_) async => true);
      await manager.delete('a');
      verify(() => mockPrefs.remove('a')).called(1);
    });

    test('delete should throw StorageException on failure', () async {
      when(() => mockPrefs.remove(any())).thenThrow(Exception('fail'));
      expect(() async => manager.delete('fail'),
          throwsA(isA<StorageException>()));
    });
  });
}