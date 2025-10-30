import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/auth/data/models/register_response_model.dart';

void main() {
  group('RegisterResponseModel', () {
    final testDateTime = DateTime(2024, 12, 31, 23, 59, 59);

    group('Constructor', () {
      test('creates instance with expiresAt', () {
        final model = RegisterResponseModel(expiresAt: testDateTime);
        expect(model.expiresAt, testDateTime);
      });
    });

    group('fromJson', () {
      test('creates model from JSON with ISO8601 datetime', () {
        final json = <String, dynamic>{
          'expiresAt': '2024-12-31T23:59:59.000Z',
        };

        final model = RegisterResponseModel.fromJson(json);

        expect(model.expiresAt.year, 2024);
        expect(model.expiresAt.month, 12);
        expect(model.expiresAt.day, 31);
      });

      test('handles various ISO8601 datetime formats', () {
        final formats = [
          '2024-01-01T00:00:00Z',
          '2024-01-01T00:00:00.000Z',
          '2024-01-01T00:00:00+00:00',
          '2024-01-01T12:30:45.123456Z',
        ];

        for (final format in formats) {
          final json = <String, dynamic>{'expiresAt': format};
          final model = RegisterResponseModel.fromJson(json);
          expect(model.expiresAt, isNotNull);
          expect(model.expiresAt, isA<DateTime>());
        }
      });

      test('parses datetime with timezone offset', () {
        final json = <String, dynamic>{
          'expiresAt': '2024-12-31T23:59:59+02:00',
        };

        final model = RegisterResponseModel.fromJson(json);
        expect(model.expiresAt, isA<DateTime>());
      });
    });

    group('toJson', () {
      test('converts model to JSON', () {
        final model = RegisterResponseModel(expiresAt: testDateTime);
        final json = model.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('expiresAt'), true);
        expect(json['expiresAt'], isA<String>());
      });

      test('produces valid ISO8601 string', () {
        final model = RegisterResponseModel(expiresAt: testDateTime);
        final json = model.toJson();
        final isoString = json['expiresAt'] as String;

        expect(isoString, contains('T'));
        expect(isoString, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')));
      });

      test('roundtrip conversion preserves datetime', () {
        final original = RegisterResponseModel(expiresAt: testDateTime);
        final json = original.toJson();
        final restored = RegisterResponseModel.fromJson(json);

        expect(
          restored.expiresAt.difference(original.expiresAt).inSeconds.abs(),
          lessThan(1),
        );
      });
    });

    group('DateTime edge cases', () {
      test('handles minimum datetime', () {
        final minDateTime = DateTime(1970, 1, 1);
        final json = <String, dynamic>{
          'expiresAt': minDateTime.toIso8601String(),
        };

        final model = RegisterResponseModel.fromJson(json);
        expect(model.expiresAt.year, 1970);
      });

      test('handles far future datetime', () {
        final futureDateTime = DateTime(2099, 12, 31, 23, 59, 59);
        final json = <String, dynamic>{
          'expiresAt': futureDateTime.toIso8601String(),
        };

        final model = RegisterResponseModel.fromJson(json);
        expect(model.expiresAt.year, 2099);
      });

      test('handles milliseconds precision', () {
        final dtWithMillis = DateTime(2024, 6, 15, 10, 30, 45, 123);
        final json = <String, dynamic>{
          'expiresAt': dtWithMillis.toIso8601String(),
        };

        final model = RegisterResponseModel.fromJson(json);
        expect(model.expiresAt.millisecond, dtWithMillis.millisecond);
      });
    });

    group('Multiple instances', () {
      test('creates different instances with different dates', () {
        final date1 = DateTime(2024, 1, 1);
        final date2 = DateTime(2024, 12, 31);

        final model1 = RegisterResponseModel(expiresAt: date1);
        final model2 = RegisterResponseModel(expiresAt: date2);

        expect(model1.expiresAt, date1);
        expect(model2.expiresAt, date2);
        expect(model1.expiresAt.isBefore(model2.expiresAt), true);
      });

      test('instances are independent', () {
        final date1 = DateTime(2024, 1, 1);
        final date2 = DateTime(2024, 1, 2);

        final model1 = RegisterResponseModel(expiresAt: date1);
        final model2 = RegisterResponseModel(expiresAt: date2);

        expect(model1.expiresAt, isNot(model2.expiresAt));
      });
    });

    group('JSON round-trip', () {
      test('complete conversion preserves all data', () {
        final original = RegisterResponseModel(expiresAt: testDateTime);

        final json = original.toJson();
        final restored = RegisterResponseModel.fromJson(json);

        expect(restored.expiresAt.toIso8601String(),
            original.expiresAt.toIso8601String());
      });

      test('multiple roundtrips maintain consistency', () {
        var model = RegisterResponseModel(expiresAt: testDateTime);
        final initialIso = model.expiresAt.toIso8601String();

        for (int i = 0; i < 3; i++) {
          final json = model.toJson();
          model = RegisterResponseModel.fromJson(json);
        }

        expect(model.expiresAt, isA<DateTime>());
      });
    });

    group('Const constructor', () {
      test('supports const instantiation', () {
        final model = RegisterResponseModel(
          expiresAt: testDateTime,
        );
        expect(model.expiresAt, testDateTime);
      });
    });
  });
}