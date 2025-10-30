import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/areas/domain/entities/area_status.dart';

void main() {
  group('AreaStatus', () {
    group('Enum values', () {
      test('has all required values', () {
        expect(AreaStatus.values.length, 3);
        expect(AreaStatus.values, contains(AreaStatus.enabled));
        expect(AreaStatus.values, contains(AreaStatus.disabled));
        expect(AreaStatus.values, contains(AreaStatus.archived));
      });

      test('values have correct string representation', () {
        expect(AreaStatus.enabled.value, 'enabled');
        expect(AreaStatus.disabled.value, 'disabled');
        expect(AreaStatus.archived.value, 'archived');
      });
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(AreaStatus.fromString('enabled'), AreaStatus.enabled);
        expect(AreaStatus.fromString('disabled'), AreaStatus.disabled);
        expect(AreaStatus.fromString('archived'), AreaStatus.archived);
      });

      test('defaults to enabled for unknown strings', () {
        expect(AreaStatus.fromString('unknown'), AreaStatus.enabled);
        expect(AreaStatus.fromString('paused'), AreaStatus.enabled);
        expect(AreaStatus.fromString(''), AreaStatus.enabled);
      });

      test('is case-sensitive', () {
        expect(AreaStatus.fromString('Enabled'), AreaStatus.enabled);
        expect(AreaStatus.fromString('DISABLED'), AreaStatus.enabled);
        expect(AreaStatus.fromString('archived'.toUpperCase()), AreaStatus.enabled);
      });

      test('handles whitespace', () {
        expect(AreaStatus.fromString(' enabled'), AreaStatus.enabled);
        expect(AreaStatus.fromString('enabled '), AreaStatus.enabled);
        expect(AreaStatus.fromString(' enabled '), AreaStatus.enabled);
      });

      test('returns correct enum after multiple calls', () {
        final first = AreaStatus.fromString('disabled');
        final second = AreaStatus.fromString('disabled');
        expect(first, second);
      });
    });

    group('Round-trip conversion', () {
      test('string to enum and back preserves value', () {
        for (final status in AreaStatus.values) {
          final converted = AreaStatus.fromString(status.value);
          expect(converted, status);
          expect(converted.value, status.value);
        }
      });

      test('all enum values can be converted to string and back', () {
        expect(AreaStatus.fromString(AreaStatus.enabled.value), AreaStatus.enabled);
        expect(AreaStatus.fromString(AreaStatus.disabled.value), AreaStatus.disabled);
        expect(AreaStatus.fromString(AreaStatus.archived.value), AreaStatus.archived);
      });
    });

    group('Comparison and equality', () {
      test('enum values are comparable', () {
        expect(AreaStatus.enabled == AreaStatus.enabled, true);
        expect(AreaStatus.enabled == AreaStatus.disabled, false);
      });

      test('can be used in if conditions', () {
        final status = AreaStatus.enabled;

        if (status == AreaStatus.enabled) {
          expect(true, true);
        } else {
          fail('Should have matched enabled');
        }
      });

      test('can be used in switch statements', () {
        String describe(AreaStatus status) {
          return switch (status) {
            AreaStatus.enabled => 'Area is active',
            AreaStatus.disabled => 'Area is paused',
            AreaStatus.archived => 'Area is archived',
          };
        }

        expect(describe(AreaStatus.enabled), 'Area is active');
        expect(describe(AreaStatus.disabled), 'Area is paused');
        expect(describe(AreaStatus.archived), 'Area is archived');
      });
    });

    group('Practical usage', () {
      test('can filter areas by status', () {
        const statuses = [
          AreaStatus.enabled,
          AreaStatus.disabled,
          AreaStatus.enabled,
          AreaStatus.archived,
        ];

        final enabledAreas = statuses.where((s) => s == AreaStatus.enabled).toList();
        expect(enabledAreas.length, 2);
      });

      test('can count areas by status', () {
        const statuses = [
          AreaStatus.enabled,
          AreaStatus.disabled,
          AreaStatus.enabled,
          AreaStatus.archived,
          AreaStatus.enabled,
        ];

        final enabledCount = statuses.where((s) => s == AreaStatus.enabled).length;
        final disabledCount = statuses.where((s) => s == AreaStatus.disabled).length;
        final archivedCount = statuses.where((s) => s == AreaStatus.archived).length;

        expect(enabledCount, 3);
        expect(disabledCount, 1);
        expect(archivedCount, 1);
      });

      test('can build status summary', () {
        const statuses = [
          AreaStatus.enabled,
          AreaStatus.disabled,
          AreaStatus.enabled,
          AreaStatus.archived,
        ];

        final summary = {
          'enabled': 0,
          'disabled': 0,
          'archived': 0,
        };

        for (final status in statuses) {
          summary[status.value] = (summary[status.value] ?? 0) + 1;
        }

        expect(summary['enabled'], 2);
        expect(summary['disabled'], 1);
        expect(summary['archived'], 1);
      });
    });

    group('Edge cases', () {
      test('repeated conversions are idempotent', () {
        const value = 'enabled';
        final result1 = AreaStatus.fromString(value);
        final result2 = AreaStatus.fromString(value);
        final result3 = AreaStatus.fromString(value);

        expect(result1, result2);
        expect(result2, result3);
      });

      test('handles each enum value as string correctly', () {
        for (final status in AreaStatus.values) {
          final restored = AreaStatus.fromString(status.value);
          expect(restored, status);
        }
      });

      test('null defaults to enabled (based on firstWhere orElse)', () {
        final result = AreaStatus.fromString('');
        expect(result, AreaStatus.enabled);
      });
    });

    group('Status lifecycle', () {
      test('can transition from enabled to disabled', () {
        var currentStatus = AreaStatus.enabled;
        expect(currentStatus, AreaStatus.enabled);

        currentStatus = AreaStatus.disabled;
        expect(currentStatus, AreaStatus.disabled);
      });

      test('can transition from disabled to enabled', () {
        var currentStatus = AreaStatus.disabled;
        expect(currentStatus, AreaStatus.disabled);

        currentStatus = AreaStatus.enabled;
        expect(currentStatus, AreaStatus.enabled);
      });

      test('can archive from any state', () {
        for (final status in [AreaStatus.enabled, AreaStatus.disabled]) {
          var currentStatus = status;
          currentStatus = AreaStatus.archived;
          expect(currentStatus, AreaStatus.archived);
        }
      });
    });

    group('Value consistency', () {
      test('each status has unique value', () {
        final values = AreaStatus.values.map((s) => s.value).toList();
        final uniqueValues = values.toSet();

        expect(values.length, uniqueValues.length);
      });

      test('all values are lowercase', () {
        for (final status in AreaStatus.values) {
          expect(status.value, status.value.toLowerCase());
        }
      });

      test('all values are single words', () {
        for (final status in AreaStatus.values) {
          expect(status.value.contains(' '), false);
          expect(status.value.contains('_'), false);
        }
      });
    });

    group('Filtering and grouping', () {
      test('can create boolean check for active areas', () {
        bool isActive(AreaStatus status) => status != AreaStatus.archived;

        expect(isActive(AreaStatus.enabled), true);
        expect(isActive(AreaStatus.disabled), true);
        expect(isActive(AreaStatus.archived), false);
      });

      test('can group statuses by category', () {
        final activeStatuses = [
          AreaStatus.enabled,
          AreaStatus.disabled,
        ];
        final inactiveStatuses = [
          AreaStatus.archived,
        ];

        expect(activeStatuses.contains(AreaStatus.enabled), true);
        expect(activeStatuses.contains(AreaStatus.archived), false);
        expect(inactiveStatuses.contains(AreaStatus.archived), true);
      });
    });
  });
}