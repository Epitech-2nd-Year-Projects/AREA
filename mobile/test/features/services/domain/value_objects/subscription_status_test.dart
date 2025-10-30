import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/domain/value_objects/subscription_status.dart';

void main() {
  group('SubscriptionStatus', () {
    group('Enum values', () {
      test('has all required values', () {
        expect(SubscriptionStatus.values.length, 4);
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.active));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.revoked));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.expired));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.needsConsent));
      });

      test('values have correct string representation', () {
        expect(SubscriptionStatus.active.value, 'active');
        expect(SubscriptionStatus.revoked.value, 'revoked');
        expect(SubscriptionStatus.expired.value, 'expired');
        expect(SubscriptionStatus.needsConsent.value, 'needs_consent');
      });
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(SubscriptionStatus.fromString('active'), SubscriptionStatus.active);
        expect(
          SubscriptionStatus.fromString('revoked'),
          SubscriptionStatus.revoked,
        );
        expect(
          SubscriptionStatus.fromString('expired'),
          SubscriptionStatus.expired,
        );
        expect(
          SubscriptionStatus.fromString('needs_consent'),
          SubscriptionStatus.needsConsent,
        );
      });

      test('defaults to needsConsent for unknown strings', () {
        expect(
          SubscriptionStatus.fromString('unknown'),
          SubscriptionStatus.needsConsent,
        );
        expect(
          SubscriptionStatus.fromString('pending'),
          SubscriptionStatus.needsConsent,
        );
        expect(SubscriptionStatus.fromString(''), SubscriptionStatus.needsConsent);
      });

      test('is case-sensitive', () {
        expect(
          SubscriptionStatus.fromString('Active'),
          SubscriptionStatus.needsConsent,
        );
        expect(
          SubscriptionStatus.fromString('REVOKED'),
          SubscriptionStatus.needsConsent,
        );
      });

      test('handles whitespace', () {
        expect(
          SubscriptionStatus.fromString(' active'),
          SubscriptionStatus.needsConsent,
        );
        expect(
          SubscriptionStatus.fromString('active '),
          SubscriptionStatus.needsConsent,
        );
      });

      test('handles snake_case correctly', () {
        expect(
          SubscriptionStatus.fromString('needs_consent'),
          SubscriptionStatus.needsConsent,
        );
      });
    });

    group('displayName getter', () {
      test('returns correct display names for all statuses', () {
        expect(SubscriptionStatus.active.displayName, 'Active');
        expect(SubscriptionStatus.revoked.displayName, 'Revoked');
        expect(SubscriptionStatus.expired.displayName, 'Expired');
        expect(SubscriptionStatus.needsConsent.displayName, 'Needs Consent');
      });

      test('display names are user-friendly and properly formatted', () {
        expect(SubscriptionStatus.active.displayName, 'Active');
        expect(SubscriptionStatus.expired.displayName, 'Expired');
        expect(SubscriptionStatus.needsConsent.displayName, 'Needs Consent');
      });

      test('multiple calls return same display name', () {
        expect(
          SubscriptionStatus.active.displayName,
          SubscriptionStatus.active.displayName,
        );
      });
    });

    group('isUsable getter', () {
      test('returns true only for active status', () {
        expect(SubscriptionStatus.active.isUsable, true);
      });

      test('returns false for other statuses', () {
        expect(SubscriptionStatus.revoked.isUsable, false);
        expect(SubscriptionStatus.expired.isUsable, false);
        expect(SubscriptionStatus.needsConsent.isUsable, false);
      });

      test('works correctly for all enum values', () {
        final expectedResults = {
          SubscriptionStatus.active: true,
          SubscriptionStatus.revoked: false,
          SubscriptionStatus.expired: false,
          SubscriptionStatus.needsConsent: false,
        };

        for (final status in SubscriptionStatus.values) {
          expect(status.isUsable, expectedResults[status]);
        }
      });
    });

    group('Round-trip conversion', () {
      test('string to enum and back preserves value', () {
        for (final status in SubscriptionStatus.values) {
          final converted = SubscriptionStatus.fromString(status.value);
          expect(converted, status);
          expect(converted.value, status.value);
        }
      });
    });

    group('Comparison and equality', () {
      test('enum values are comparable', () {
        expect(SubscriptionStatus.active == SubscriptionStatus.active, true);
        expect(SubscriptionStatus.active == SubscriptionStatus.revoked, false);
      });

      test('can be used in switch statements', () {
        String describe(SubscriptionStatus status) {
          return switch (status) {
            SubscriptionStatus.active => 'Ready to use',
            SubscriptionStatus.revoked => 'Connection removed',
            SubscriptionStatus.expired => 'Access expired',
            SubscriptionStatus.needsConsent => 'Authorization needed',
          };
        }

        expect(describe(SubscriptionStatus.active), 'Ready to use');
        expect(describe(SubscriptionStatus.revoked), 'Connection removed');
        expect(describe(SubscriptionStatus.expired), 'Access expired');
      });

      test('can be used in if conditions', () {
        final status = SubscriptionStatus.active;

        if (status == SubscriptionStatus.active) {
          expect(true, true);
        } else {
          fail('Should have matched active');
        }
      });
    });

    group('Filtering and grouping', () {
      test('can filter active subscriptions', () {
        const statuses = [
          SubscriptionStatus.active,
          SubscriptionStatus.revoked,
          SubscriptionStatus.active,
          SubscriptionStatus.expired,
        ];

        final activeSubscriptions =
            statuses.where((s) => s.isUsable).toList();
        expect(activeSubscriptions.length, 2);
      });

      test('can filter inactive subscriptions', () {
        const statuses = [
          SubscriptionStatus.active,
          SubscriptionStatus.revoked,
          SubscriptionStatus.expired,
          SubscriptionStatus.needsConsent,
        ];

        final inactiveSubscriptions =
            statuses.where((s) => !s.isUsable).toList();
        expect(inactiveSubscriptions.length, 3);
      });

      test('can count by status', () {
        const statuses = [
          SubscriptionStatus.active,
          SubscriptionStatus.active,
          SubscriptionStatus.revoked,
          SubscriptionStatus.expired,
          SubscriptionStatus.expired,
          SubscriptionStatus.needsConsent,
        ];

        final activeCount = statuses.where((s) => s == SubscriptionStatus.active).length;
        final revokedCount = statuses.where((s) => s == SubscriptionStatus.revoked).length;
        final expiredCount = statuses.where((s) => s == SubscriptionStatus.expired).length;

        expect(activeCount, 2);
        expect(revokedCount, 1);
        expect(expiredCount, 2);
      });
    });

    group('Practical usage', () {
      test('can check subscription needs action', () {
        bool needsAction(SubscriptionStatus status) =>
            status == SubscriptionStatus.needsConsent ||
            status == SubscriptionStatus.expired;

        expect(needsAction(SubscriptionStatus.active), false);
        expect(needsAction(SubscriptionStatus.needsConsent), true);
        expect(needsAction(SubscriptionStatus.expired), true);
      });

      test('can show status-appropriate message', () {
        String getStatusMessage(SubscriptionStatus status) {
          return switch (status) {
            SubscriptionStatus.active => 'Your connection is active',
            SubscriptionStatus.revoked =>
              'You have revoked access to this service',
            SubscriptionStatus.expired =>
              'Your access has expired. Please reconnect.',
            SubscriptionStatus.needsConsent =>
              'Please authorize this service to continue',
          };
        }

        expect(getStatusMessage(SubscriptionStatus.active),
            'Your connection is active');
        expect(getStatusMessage(SubscriptionStatus.expired),
            'Your access has expired. Please reconnect.');
      });

      test('can build subscription summary', () {
        const subscriptions = [
          SubscriptionStatus.active,
          SubscriptionStatus.active,
          SubscriptionStatus.active,
          SubscriptionStatus.revoked,
          SubscriptionStatus.expired,
          SubscriptionStatus.needsConsent,
        ];

        final summary = {
          'active': subscriptions.where((s) => s == SubscriptionStatus.active).length,
          'revoked': subscriptions.where((s) => s == SubscriptionStatus.revoked).length,
          'expired': subscriptions.where((s) => s == SubscriptionStatus.expired).length,
          'needsConsent':
              subscriptions.where((s) => s == SubscriptionStatus.needsConsent).length,
        };

        expect(summary['active'], 3);
        expect(summary['revoked'], 1);
        expect(summary['expired'], 1);
        expect(summary['needsConsent'], 1);
      });
    });

    group('Edge cases', () {
      test('repeated conversions are idempotent', () {
        const value = 'active';
        final result1 = SubscriptionStatus.fromString(value);
        final result2 = SubscriptionStatus.fromString(value);
        final result3 = SubscriptionStatus.fromString(value);

        expect(result1, result2);
        expect(result2, result3);
      });

      test('handles each enum value as string correctly', () {
        for (final status in SubscriptionStatus.values) {
          final restored = SubscriptionStatus.fromString(status.value);
          expect(restored, status);
        }
      });
    });

    group('Value consistency', () {
      test('each status has unique value', () {
        final values =
            SubscriptionStatus.values.map((s) => s.value).toList();
        final uniqueValues = values.toSet();

        expect(values.length, uniqueValues.length);
      });

      test('each status has unique display name', () {
        final displayNames = SubscriptionStatus.values
            .map((s) => s.displayName)
            .toList();
        final uniqueNames = displayNames.toSet();

        expect(displayNames.length, uniqueNames.length);
      });

      test('all values are lowercase', () {
        for (final status in SubscriptionStatus.values) {
          expect(status.value, status.value.toLowerCase());
        }
      });
    });
  });
}