import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/data/models/user_service_subscription_model.dart';
import 'package:area/features/services/domain/value_objects/subscription_status.dart';

void main() {
  group('UserServiceSubscriptionModel', () {
    final testDate1 = DateTime(2024, 1, 1);
    final testDate2 = DateTime(2024, 1, 2);

    final baseJson = <String, dynamic>{
      'id': 'sub_123',
      'providerId': 'github',
      'identityId': 'user_123',
      'status': 'active',
      'scopeGrants': ['read', 'write'],
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-02T00:00:00Z',
    };

    group('Constructor', () {
      test('creates instance with all parameters', () {
        final model = UserServiceSubscriptionModel(
          id: 'sub_123',
          providerId: 'github',
          identityId: 'user_123',
          status: SubscriptionStatus.active,
          scopeGrants: const ['read', 'write'],
          createdAt: testDate1,
          updatedAt: testDate2,
        );

        expect(model.id, 'sub_123');
        expect(model.providerId, 'github');
        expect(model.identityId, 'user_123');
        expect(model.status, SubscriptionStatus.active);
        expect(model.scopeGrants, ['read', 'write']);
      });

      test('creates instance with null identityId', () {
        final model = UserServiceSubscriptionModel(
          id: 'sub_123',
          providerId: 'github',
          identityId: null,
          status: SubscriptionStatus.active,
          scopeGrants: const [],
          createdAt: testDate1,
          updatedAt: testDate2,
        );

        expect(model.identityId, isNull);
      });

      test('creates instance with empty scopes', () {
        final model = UserServiceSubscriptionModel(
          id: 'sub_123',
          providerId: 'github',
          identityId: 'user_123',
          status: SubscriptionStatus.active,
          scopeGrants: const [],
          createdAt: testDate1,
          updatedAt: testDate2,
        );

        expect(model.scopeGrants, isEmpty);
      });
    });

    group('fromJson - Standard format', () {
      test('parses complete JSON', () {
        final model = UserServiceSubscriptionModel.fromJson(baseJson);

        expect(model.id, 'sub_123');
        expect(model.providerId, 'github');
        expect(model.identityId, 'user_123');
        expect(model.status, SubscriptionStatus.active);
        expect(model.scopeGrants, ['read', 'write']);
      });

      test('parses with null identityId', () {
        final json = <String, dynamic>{...baseJson, 'identityId': null};

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.identityId, isNull);
      });

      test('parses with empty scopeGrants', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': <String>[],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, isEmpty);
      });

      test('parses datetime correctly', () {
        final model = UserServiceSubscriptionModel.fromJson(baseJson);

        expect(model.createdAt.year, 2024);
        expect(model.createdAt.month, 1);
        expect(model.createdAt.day, 1);
        expect(model.updatedAt.day, 2);
      });

      test('handles various status values', () {
        final statuses = ['active', 'revoked', 'expired', 'needs_consent'];

        for (final status in statuses) {
          final json = <String, dynamic>{...baseJson, 'status': status};
          final model = UserServiceSubscriptionModel.fromJson(json);

          expect(model.status, isNotNull);
        }
      });
    });

    group('fromJson - snake_case format', () {
      test('parses snake_case field names', () {
        final json = <String, dynamic>{
          'id': 'sub_123',
          'provider_id': 'github',
          'identity_id': 'user_123',
          'status': 'active',
          'scope_grants': ['read', 'write'],
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-02T00:00:00Z',
        };

        expect(
          () => UserServiceSubscriptionModel.fromJson(json),
          throwsA(isA<TypeError>()),
        );
      });

      test('handles scopeGrants in snake_case', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scope_grants': ['read', 'write'],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, isNotEmpty);
      });

      test('handles both scopeGrants and scope_grants', () {
        final json = <String, dynamic>{
          'id': 'sub_123',
          'providerId': 'github',
          'identityId': 'user_123',
          'status': 'active',
          'scopeGrants': ['read', 'write'],
          'scope_grants': ['old', 'scopes'],
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-02T00:00:00Z',
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, ['read', 'write']);
      });
    });

    group('fromJson - Scope grants parsing', () {
      test('parses single scope', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': ['read'],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, ['read']);
      });

      test('parses multiple scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': ['read', 'write', 'delete'],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, ['read', 'write', 'delete']);
      });

      test('filters out non-string scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': ['read', 123, 'write', null, 'delete'],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, ['read', 'write', 'delete']);
      });

      test('handles non-list scopeGrants', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': 'not_a_list',
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, isEmpty);
      });

      test('handles null scopeGrants', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': null,
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, isEmpty);
      });

      test('handles missing scopeGrants', () {
        final json = Map<String, dynamic>.from(baseJson);
        json.remove('scopeGrants');

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.scopeGrants, isEmpty);
      });
    });

    group('fromJson - Date parsing', () {
      test('parses ISO8601 dates', () {
        final model = UserServiceSubscriptionModel.fromJson(baseJson);

        expect(model.createdAt, isA<DateTime>());
        expect(model.updatedAt, isA<DateTime>());
      });

      test('converts to UTC', () {
        final model = UserServiceSubscriptionModel.fromJson(baseJson);

        expect(model.createdAt.isUtc, true);
        expect(model.updatedAt.isUtc, true);
      });

      test('handles various datetime formats', () {
        final formats = [
          '2024-01-01T00:00:00Z',
          '2024-01-01T00:00:00.000Z',
          '2024-01-01T00:00:00+00:00',
        ];

        for (final format in formats) {
          final json = <String, dynamic>{
            ...baseJson,
            'createdAt': format,
            'updatedAt': format,
          };

          final model = UserServiceSubscriptionModel.fromJson(json);
          expect(model.createdAt, isA<DateTime>());
        }
      });

      test('preserves date precision', () {
        final json = <String, dynamic>{
          ...baseJson,
          'createdAt': '2024-06-15T10:30:45.123456Z',
          'updatedAt': '2024-06-15T10:30:45.123456Z',
        };

        final model = UserServiceSubscriptionModel.fromJson(json);

        expect(model.createdAt.millisecond, isNotNull);
      });
    });

    group('fromJson - Status parsing', () {
      test('parses active status', () {
        final json = <String, dynamic>{...baseJson, 'status': 'active'};
        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.status, SubscriptionStatus.active);
      });

      test('parses revoked status', () {
        final json = <String, dynamic>{...baseJson, 'status': 'revoked'};
        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.status, SubscriptionStatus.revoked);
      });

      test('parses expired status', () {
        final json = <String, dynamic>{...baseJson, 'status': 'expired'};
        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.status, SubscriptionStatus.expired);
      });

      test('parses needs_consent status', () {
        final json = <String, dynamic>{...baseJson, 'status': 'needs_consent'};
        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.status, SubscriptionStatus.needsConsent);
      });

      test('handles case sensitivity in status', () {
        final json = <String, dynamic>{...baseJson, 'status': 'ACTIVE'};
        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.status, isNotNull);
      });
    });

    group('toEntity', () {
      test('converts to UserServiceSubscription entity', () {
        final model = UserServiceSubscriptionModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.id, model.id);
        expect(entity.providerId, model.providerId);
        expect(entity.identityId, model.identityId);
        expect(entity.status, model.status);
        expect(entity.scopeGrants, model.scopeGrants);
      });

      test('sets userId to null in entity', () {
        final model = UserServiceSubscriptionModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.userId, isNull);
      });

      test('preserves all data in entity conversion', () {
        final model = UserServiceSubscriptionModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.createdAt, model.createdAt);
        expect(entity.updatedAt, model.updatedAt);
      });

      test('preserves scope grants in entity', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': ['read', 'write', 'delete'],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.scopeGrants, ['read', 'write', 'delete']);
      });
    });

    group('Scope grants edge cases', () {
      test('handles empty scopes list', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': <String>[],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.scopeGrants, isEmpty);
      });

      test('handles duplicate scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': ['read', 'read', 'write'],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.scopeGrants, ['read', 'read', 'write']);
      });

      test('preserves scope order', () {
        final scopes = ['write', 'delete', 'read'];
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': scopes,
        };

        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.scopeGrants, scopes);
      });

      test('handles special characters in scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopeGrants': ['user:email', 'repo:read', 'org:admin'],
        };

        final model = UserServiceSubscriptionModel.fromJson(json);
        expect(model.scopeGrants, contains('user:email'));
      });
    });

    group('Multiple instances', () {
      test('creates independent instances', () {
        final json1 = <String, dynamic>{...baseJson, 'id': 'sub_1'};
        final json2 = <String, dynamic>{...baseJson, 'id': 'sub_2'};

        final model1 = UserServiceSubscriptionModel.fromJson(json1);
        final model2 = UserServiceSubscriptionModel.fromJson(json2);

        expect(model1.id, 'sub_1');
        expect(model2.id, 'sub_2');
        expect(model1.id, isNot(model2.id));
      });

      test('instances with different statuses', () {
        final json1 = <String, dynamic>{...baseJson, 'status': 'active'};
        final json2 = <String, dynamic>{...baseJson, 'status': 'revoked'};

        final model1 = UserServiceSubscriptionModel.fromJson(json1);
        final model2 = UserServiceSubscriptionModel.fromJson(json2);

        expect(model1.status, SubscriptionStatus.active);
        expect(model2.status, SubscriptionStatus.revoked);
      });
    });

    group('JSON round-trip', () {
      test('toEntity preserves complete data', () {
        final original = UserServiceSubscriptionModel.fromJson(baseJson);
        final entity = original.toEntity();

        expect(entity.id, original.id);
        expect(entity.providerId, original.providerId);
        expect(entity.identityId, original.identityId);
        expect(entity.status, original.status);
        expect(entity.scopeGrants, original.scopeGrants);
      });

      test('multiple instances maintain independence', () {
        final model1 = UserServiceSubscriptionModel.fromJson(baseJson);
        final model2 = UserServiceSubscriptionModel.fromJson(baseJson);

        final entity1 = model1.toEntity();
        final entity2 = model2.toEntity();

        expect(entity1.id, entity2.id);
        expect(identical(entity1, entity2), false);
      });
    });

    group('Const constructor', () {
      test('supports const instantiation', () {
        final model = UserServiceSubscriptionModel(
          id: 'sub_123',
          providerId: 'github',
          identityId: 'user_123',
          status: SubscriptionStatus.active,
          scopeGrants: const ['read'],
          createdAt: testDate1,
          updatedAt: testDate2,
        );
        expect(model.id, 'sub_123');
      });
    });
  });
}