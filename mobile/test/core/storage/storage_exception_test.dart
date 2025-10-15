import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/storage/exceptions/storage_exceptions.dart';

void main() {
  group('StorageException', () {
    test('toString returns correct message', () {
      final e = StorageException('Error test');
      expect(e.message, 'Error test');
      expect(e.toString(), 'StorageException : Error test');
    });
  });
}