import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/domain/value_objects/service_category.dart';

void main() {
  group('ServiceCategory', () {
    group('Enum values', () {
      test('has all required values', () {
        expect(ServiceCategory.values.length, 6);
        expect(ServiceCategory.values, contains(ServiceCategory.social));
        expect(ServiceCategory.values, contains(ServiceCategory.productivity));
        expect(ServiceCategory.values, contains(ServiceCategory.communication));
        expect(ServiceCategory.values, contains(ServiceCategory.storage));
        expect(ServiceCategory.values, contains(ServiceCategory.development));
        expect(ServiceCategory.values, contains(ServiceCategory.other));
      });

      test('values have correct string representation', () {
        expect(ServiceCategory.social.value, 'social');
        expect(ServiceCategory.productivity.value, 'productivity');
        expect(ServiceCategory.communication.value, 'communication');
        expect(ServiceCategory.storage.value, 'storage');
        expect(ServiceCategory.development.value, 'development');
        expect(ServiceCategory.other.value, 'other');
      });
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(ServiceCategory.fromString('social'), ServiceCategory.social);
        expect(
          ServiceCategory.fromString('productivity'),
          ServiceCategory.productivity,
        );
        expect(
          ServiceCategory.fromString('communication'),
          ServiceCategory.communication,
        );
        expect(ServiceCategory.fromString('storage'), ServiceCategory.storage);
        expect(
          ServiceCategory.fromString('development'),
          ServiceCategory.development,
        );
        expect(ServiceCategory.fromString('other'), ServiceCategory.other);
      });

      test('defaults to other for unknown strings', () {
        expect(ServiceCategory.fromString('unknown'), ServiceCategory.other);
        expect(ServiceCategory.fromString('gaming'), ServiceCategory.other);
        expect(ServiceCategory.fromString(''), ServiceCategory.other);
      });

      test('is case-sensitive', () {
        expect(ServiceCategory.fromString('Social'), ServiceCategory.other);
        expect(ServiceCategory.fromString('PRODUCTIVITY'), ServiceCategory.other);
        expect(
          ServiceCategory.fromString('social'.toUpperCase()),
          ServiceCategory.other,
        );
      });

      test('handles whitespace', () {
        expect(ServiceCategory.fromString(' social'), ServiceCategory.other);
        expect(ServiceCategory.fromString('social '), ServiceCategory.other);
        expect(ServiceCategory.fromString(' social '), ServiceCategory.other);
      });
    });

    group('displayName getter', () {
      test('returns correct display names for all categories', () {
        expect(ServiceCategory.social.displayName, 'Social Media');
        expect(ServiceCategory.productivity.displayName, 'Productivity');
        expect(ServiceCategory.communication.displayName, 'Communication');
        expect(ServiceCategory.storage.displayName, 'Cloud Storage');
        expect(ServiceCategory.development.displayName, 'Development');
        expect(ServiceCategory.other.displayName, 'Other');
      });

      test('display names are user-friendly', () {
        final displayNames = ServiceCategory.values.map((c) => c.displayName);
        
        for (final name in displayNames) {
          expect(name.isNotEmpty, true);
          expect(name.contains('_'), false);
        }
      });

      test('multiple calls return same display name', () {
        expect(
          ServiceCategory.social.displayName,
          ServiceCategory.social.displayName,
        );
      });
    });

    group('All categories have display names', () {
      test('no category returns null display name', () {
        for (final category in ServiceCategory.values) {
          expect(category.displayName, isNotNull);
          expect(category.displayName.isNotEmpty, true);
        }
      });
    });

    group('Round-trip conversion', () {
      test('string to enum and back preserves value', () {
        for (final category in ServiceCategory.values) {
          final converted = ServiceCategory.fromString(category.value);
          expect(converted, category);
          expect(converted.value, category.value);
        }
      });
    });

    group('Category filtering', () {
      test('can filter categories by displayName', () {
        final communicationCategories = ServiceCategory.values
            .where((c) => c.displayName.contains('Communication'))
            .toList();

        expect(communicationCategories.length, 1);
        expect(communicationCategories.first, ServiceCategory.communication);
      });

      test('can find categories that require storage', () {
        final storageRelated = ServiceCategory.values
            .where((c) => c.displayName.toLowerCase().contains('storage'))
            .toList();

        expect(storageRelated, contains(ServiceCategory.storage));
      });
    });

    group('Edge cases', () {
      test('repeated conversions are idempotent', () {
        const value = 'productivity';
        final result1 = ServiceCategory.fromString(value);
        final result2 = ServiceCategory.fromString(value);
        final result3 = ServiceCategory.fromString(value);

        expect(result1, result2);
        expect(result2, result3);
      });

      test('handles each enum value as string correctly', () {
        for (final category in ServiceCategory.values) {
          final restored = ServiceCategory.fromString(category.value);
          expect(restored, category);
        }
      });
    });

    group('Comparison and equality', () {
      test('enum values are comparable', () {
        expect(ServiceCategory.social == ServiceCategory.social, true);
        expect(ServiceCategory.social == ServiceCategory.productivity, false);
      });

      test('can be used in switch statements', () {
        String describe(ServiceCategory category) {
          return switch (category) {
            ServiceCategory.social => 'Connect with friends',
            ServiceCategory.productivity => 'Get things done',
            ServiceCategory.communication => 'Stay in touch',
            ServiceCategory.storage => 'Store your files',
            ServiceCategory.development => 'Build and deploy',
            ServiceCategory.other => 'Other services',
          };
        }

        expect(describe(ServiceCategory.productivity), 'Get things done');
        expect(describe(ServiceCategory.social), 'Connect with friends');
      });

      test('can be used in if conditions', () {
        final category = ServiceCategory.development;

        if (category == ServiceCategory.development) {
          expect(true, true);
        } else {
          fail('Should have matched development');
        }
      });
    });

    group('Practical usage', () {
      test('can group services by category', () {
        final categories = <ServiceCategory, List<String>>{
          ServiceCategory.social: [],
          ServiceCategory.productivity: [],
          ServiceCategory.communication: [],
          ServiceCategory.storage: [],
          ServiceCategory.development: [],
          ServiceCategory.other: [],
        };

        categories[ServiceCategory.social]!.add('Facebook');
        categories[ServiceCategory.development]!.add('GitHub');
        categories[ServiceCategory.productivity]!.add('Notion');

        expect(categories[ServiceCategory.social]!.length, 1);
        expect(categories[ServiceCategory.development]!.length, 1);
        expect(categories[ServiceCategory.communication]!.length, 0);
      });

      test('can filter by category for UI display', () {
        final userCategories = [
          ServiceCategory.social,
          ServiceCategory.development,
          ServiceCategory.productivity,
        ];

        final developmentServices = userCategories
            .where((c) => c == ServiceCategory.development)
            .toList();

        expect(developmentServices.length, 1);
        expect(developmentServices.first, ServiceCategory.development);
      });
    });

    group('Value consistency', () {
      test('each category has unique value', () {
        final values = ServiceCategory.values.map((c) => c.value).toList();
        final uniqueValues = values.toSet();

        expect(values.length, uniqueValues.length);
      });

      test('each category has unique display name', () {
        final displayNames =
            ServiceCategory.values.map((c) => c.displayName).toList();
        final uniqueNames = displayNames.toSet();

        expect(displayNames.length, uniqueNames.length);
      });
    });
  });
}