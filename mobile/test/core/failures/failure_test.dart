import 'package:area/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('should correctly compare equality using Equatable', () {
      const failure1 = NetworkFailure('Error');
      const failure2 = NetworkFailure('Error');
      const failure3 = NetworkFailure('Different');

      expect(failure1, equals(failure2));
      expect(failure1 == failure3, isFalse);
    });

    test('UnknownFailure should have default message', () {
      const unknown = UnknownFailure();
      expect(unknown.message, 'Unknown error');
      expect(unknown.props, contains('Unknown error'));
    });

    test('Different failure subclasses should behave independently', () {
      const n = NetworkFailure('Net');
      const u = UnauthorizedFailure('Unauth');
      const s = StorageFailure('Store');
      const uk = UnknownFailure('Other');

      expect(n.message, 'Net');
      expect(u.message, 'Unauth');
      expect(s.message, 'Store');
      expect(uk.message, 'Other');
    });
  });
}