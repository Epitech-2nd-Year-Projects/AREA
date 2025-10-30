import 'package:area/features/services/data/models/user_service_subscription_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/data/models/subscribe_exchange_response_model.dart';
import 'package:area/features/services/data/models/identity_summary_model.dart';
import 'package:area/features/services/domain/value_objects/subscription_status.dart';

void main() {
  group('SubscribeExchangeResponseModel', () {
    final baseSubscriptionJson = <String, dynamic>{
      'id': 'sub_123',
      'providerId': 'github',
      'identityId': 'user_123',
      'status': 'active',
      'scopeGrants': ['read', 'write'],
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-02T00:00:00Z',
    };

    final baseIdentityJson = <String, dynamic>{
      'id': 'identity_123',
      'provider': 'github',
      'subject': 'octocat',
      'scopes': ['user:email', 'repo'],
      'connectedAt': '2024-01-01T10:00:00Z',
      'expiresAt': null,
    };

    final completeJson = <String, dynamic>{
      'subscription': baseSubscriptionJson,
      'identity': baseIdentityJson,
    };

    group('Constructor', () {
      test('creates instance with subscription only', () {
        final sub = _createSubscription();
        final model = SubscribeExchangeResponseModel(
          subscription: sub,
        );

        expect(model.subscription, sub);
        expect(model.identity, isNull);
      });

      test('creates instance with subscription and identity', () {
        final sub = _createSubscription();
        final identity = _createIdentity();

        final model = SubscribeExchangeResponseModel(
          subscription: sub,
          identity: identity,
        );

        expect(model.subscription, sub);
        expect(model.identity, identity);
      });
    });

    group('fromJson - Complete structure', () {
      test('parses complete JSON with subscription and identity', () {
        final model = SubscribeExchangeResponseModel.fromJson(completeJson);

        expect(model.subscription.id, 'sub_123');
        expect(model.subscription.providerId, 'github');
        expect(model.identity, isNotNull);
        expect(model.identity!.id, 'identity_123');
        expect(model.identity!.provider, 'github');
      });

      test('parses with subscription only', () {
        final json = <String, dynamic>{
          'subscription': baseSubscriptionJson,
        };

        final model = SubscribeExchangeResponseModel.fromJson(json);

        expect(model.subscription.id, 'sub_123');
        expect(model.identity, isNull);
      });

      test('parses subscription data correctly', () {
        final model = SubscribeExchangeResponseModel.fromJson(completeJson);

        expect(model.subscription.id, 'sub_123');
        expect(model.subscription.providerId, 'github');
        expect(model.subscription.identityId, 'user_123');
        expect(model.subscription.status, SubscriptionStatus.active);
        expect(model.subscription.scopeGrants, ['read', 'write']);
      });

      test('parses identity data correctly', () {
        final model = SubscribeExchangeResponseModel.fromJson(completeJson);

        expect(model.identity!.id, 'identity_123');
        expect(model.identity!.provider, 'github');
        expect(model.identity!.subject, 'octocat');
        expect(model.identity!.scopes, ['user:email', 'repo']);
      });
    });

    group('fromJson - Error handling', () {
      test('throws when subscription is missing', () {
        final json = <String, dynamic>{
          'identity': baseIdentityJson,
        };

        expect(
          () => SubscribeExchangeResponseModel.fromJson(json),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when subscription is not a map', () {
        final json = <String, dynamic>{
          'subscription': 'not_a_map',
          'identity': baseIdentityJson,
        };

        expect(
          () => SubscribeExchangeResponseModel.fromJson(json),
          throwsA(isA<Exception>()),
        );
      });

      test('throws with descriptive message for invalid subscription', () {
        final json = <String, dynamic>{
          'subscription': 'invalid',
        };

        expect(
          () => SubscribeExchangeResponseModel.fromJson(json),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid subscription exchange response'),
            ),
          ),
        );
      });

      test('handles null subscription gracefully', () {
        final json = <String, dynamic>{
          'subscription': null,
          'identity': baseIdentityJson,
        };

        expect(
          () => SubscribeExchangeResponseModel.fromJson(json),
          throwsA(isA<Exception>()),
        );
      });

      test('ignores identity when not a map', () {
        final json = <String, dynamic>{
          'subscription': baseSubscriptionJson,
          'identity': 'not_a_map',
        };

        final model = SubscribeExchangeResponseModel.fromJson(json);

        expect(model.subscription, isNotNull);
        expect(model.identity, isNull);
      });

      test('ignores null identity', () {
        final json = <String, dynamic>{
          'subscription': baseSubscriptionJson,
          'identity': null,
        };

        final model = SubscribeExchangeResponseModel.fromJson(json);

        expect(model.subscription, isNotNull);
        expect(model.identity, isNull);
      });

      test('handles missing identity', () {
        final json = <String, dynamic>{
          'subscription': baseSubscriptionJson,
        };

        final model = SubscribeExchangeResponseModel.fromJson(json);

        expect(model.subscription, isNotNull);
        expect(model.identity, isNull);
      });
    });

    group('toEntity', () {
      test('converts to ServiceSubscriptionExchangeResult entity', () {
        final model = SubscribeExchangeResponseModel.fromJson(completeJson);
        final entity = model.toEntity();

        expect(entity.subscription.id, 'sub_123');
        expect(entity.subscription.providerId, 'github');
      });

      test('preserves subscription in entity', () {
        final model = SubscribeExchangeResponseModel.fromJson(completeJson);
        final entity = model.toEntity();

        expect(entity.subscription, isNotNull);
        expect(entity.subscription.status, SubscriptionStatus.active);
      });

      test('preserves identity in entity', () {
        final model = SubscribeExchangeResponseModel.fromJson(completeJson);
        final entity = model.toEntity();

        expect(entity.identity, isNotNull);
        expect(entity.identity!.id, 'identity_123');
        expect(entity.identity!.provider, 'github');
      });

      test('handles null identity in entity conversion', () {
        final json = <String, dynamic>{
          'subscription': baseSubscriptionJson,
        };

        final model = SubscribeExchangeResponseModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.subscription, isNotNull);
        expect(entity.identity, isNull);
      });
    });

    group('Const constructor', () {
      test('supports const instantiation', () {
        final sub = _createSubscription();
        final model = SubscribeExchangeResponseModel(
          subscription: sub,
        );
        expect(model.subscription, sub);
      });
    });

    group('Multiple instances', () {
      test('creates independent instances', () {
        final model1 = SubscribeExchangeResponseModel.fromJson(completeJson);

        final json2 = <String, dynamic>{
          'subscription': <String, dynamic>{
            ...baseSubscriptionJson,
            'providerId': 'gitlab',
          },
        };

        final model2 = SubscribeExchangeResponseModel.fromJson(json2);

        expect(model1.subscription.providerId, 'github');
        expect(model2.subscription.providerId, 'gitlab');
      });
    });

    group('JSON round-trip', () {
      test('preserves all data through toEntity', () {
        final model = SubscribeExchangeResponseModel.fromJson(completeJson);
        final entity = model.toEntity();

        expect(entity.subscription.id, model.subscription.id);
        expect(entity.identity!.id, model.identity!.id);
      });
    });
  });

  group('IdentitySummaryModel', () {
    final testConnectedAt = DateTime(2024, 1, 1, 10, 0, 0);
    final testExpiresAt = DateTime(2025, 1, 1, 10, 0, 0);

    final baseJson = <String, dynamic>{
      'id': 'identity_123',
      'provider': 'github',
      'subject': 'octocat',
      'scopes': ['user:email', 'repo'],
      'connectedAt': '2024-01-01T10:00:00Z',
      'expiresAt': '2025-01-01T10:00:00Z',
    };

    group('Constructor', () {
      test('creates instance with all parameters', () {
        final model = IdentitySummaryModel(
          id: 'identity_123',
          provider: 'github',
          subject: 'octocat',
          scopes: const ['user:email', 'repo'],
          connectedAt: testConnectedAt,
          expiresAt: testExpiresAt,
        );

        expect(model.id, 'identity_123');
        expect(model.provider, 'github');
        expect(model.subject, 'octocat');
        expect(model.scopes, ['user:email', 'repo']);
        expect(model.expiresAt, testExpiresAt);
      });

      test('creates instance with null expiresAt', () {
        final model = IdentitySummaryModel(
          id: 'identity_123',
          provider: 'github',
          subject: 'octocat',
          scopes: const ['user:email'],
          connectedAt: testConnectedAt,
          expiresAt: null,
        );

        expect(model.expiresAt, isNull);
      });

      test('creates instance with empty scopes', () {
        final model = IdentitySummaryModel(
          id: 'identity_123',
          provider: 'github',
          subject: 'octocat',
          scopes: const [],
          connectedAt: testConnectedAt,
          expiresAt: null,
        );

        expect(model.scopes, isEmpty);
      });
    });

    group('fromJson - Complete structure', () {
      test('parses complete JSON', () {
        final model = IdentitySummaryModel.fromJson(baseJson);

        expect(model.id, 'identity_123');
        expect(model.provider, 'github');
        expect(model.subject, 'octocat');
        expect(model.scopes, ['user:email', 'repo']);
        expect(model.expiresAt, isNotNull);
      });

      test('parses without expiresAt', () {
        final json = <String, dynamic>{
          'id': 'identity_123',
          'provider': 'github',
          'subject': 'octocat',
          'scopes': ['user:email'],
          'connectedAt': '2024-01-01T10:00:00Z',
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.expiresAt, isNull);
      });

      test('parses with null expiresAt', () {
        final json = <String, dynamic>{
          ...baseJson,
          'expiresAt': null,
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.expiresAt, isNull);
      });

      test('parses datetime fields correctly', () {
        final model = IdentitySummaryModel.fromJson(baseJson);

        expect(model.connectedAt.year, 2024);
        expect(model.expiresAt!.year, 2025);
      });
    });

    group('fromJson - Scopes parsing', () {
      test('parses single scope', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': ['user:email'],
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, ['user:email']);
      });

      test('parses multiple scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': ['user:email', 'repo', 'org:admin'],
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, ['user:email', 'repo', 'org:admin']);
      });

      test('filters out non-string scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': ['user:email', 123, 'repo', null, true],
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, ['user:email', 'repo']);
      });

      test('handles non-list scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': 'not_a_list',
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, isEmpty);
      });

      test('handles null scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': null,
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, isEmpty);
      });

      test('handles empty scopes list', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': <String>[],
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, isEmpty);
      });

      test('preserves scope order', () {
        final scopes = ['repo', 'user:email', 'org:admin'];
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': scopes,
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, scopes);
      });

      test('handles duplicate scopes', () {
        final json = <String, dynamic>{
          ...baseJson,
          'scopes': ['user:email', 'user:email', 'repo'],
        };

        final model = IdentitySummaryModel.fromJson(json);

        expect(model.scopes, ['user:email', 'user:email', 'repo']);
      });
    });

    group('fromJson - Date parsing', () {
      test('converts dates to UTC', () {
        final model = IdentitySummaryModel.fromJson(baseJson);

        expect(model.connectedAt.isUtc, true);
        expect(model.expiresAt!.isUtc, true);
      });

      test('handles various datetime formats', () {
        final formats = [
          '2024-01-01T10:00:00Z',
          '2024-01-01T10:00:00.000Z',
          '2024-01-01T10:00:00+00:00',
        ];

        for (final format in formats) {
          final json = <String, dynamic>{
            ...baseJson,
            'connectedAt': format,
            'expiresAt': format,
          };

          final model = IdentitySummaryModel.fromJson(json);
          expect(model.connectedAt, isA<DateTime>());
          expect(model.expiresAt, isA<DateTime>());
        }
      });
    });

    group('toEntity', () {
      test('converts to ServiceIdentitySummary entity', () {
        final model = IdentitySummaryModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.id, 'identity_123');
        expect(entity.provider, 'github');
        expect(entity.subject, 'octocat');
      });

      test('preserves all fields in entity', () {
        final model = IdentitySummaryModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.scopes, model.scopes);
        expect(entity.connectedAt, model.connectedAt);
        expect(entity.expiresAt, model.expiresAt);
      });

      test('handles null expiresAt in entity', () {
        final json = <String, dynamic>{
          ...baseJson,
          'expiresAt': null,
        };

        final model = IdentitySummaryModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.expiresAt, isNull);
      });
    });

    group('Provider variations', () {
      test('handles different providers', () {
        final providers = ['github', 'gitlab', 'bitbucket', 'google'];

        for (final provider in providers) {
          final json = <String, dynamic>{
            ...baseJson,
            'provider': provider,
          };

          final model = IdentitySummaryModel.fromJson(json);
          expect(model.provider, provider);
        }
      });

      test('handles provider with special characters', () {
        final json = <String, dynamic>{
          ...baseJson,
          'provider': 'github-enterprise',
        };

        final model = IdentitySummaryModel.fromJson(json);
        expect(model.provider, 'github-enterprise');
      });
    });

    group('Subject handling', () {
      test('handles username subjects', () {
        final json = <String, dynamic>{
          ...baseJson,
          'subject': 'octocat',
        };

        final model = IdentitySummaryModel.fromJson(json);
        expect(model.subject, 'octocat');
      });

      test('handles email subjects', () {
        final json = <String, dynamic>{
          ...baseJson,
          'subject': 'user@example.com',
        };

        final model = IdentitySummaryModel.fromJson(json);
        expect(model.subject, 'user@example.com');
      });

      test('handles UUID subjects', () {
        final json = <String, dynamic>{
          ...baseJson,
          'subject': '123e4567-e89b-12d3-a456-426614174000',
        };

        final model = IdentitySummaryModel.fromJson(json);
        expect(model.subject, '123e4567-e89b-12d3-a456-426614174000');
      });
    });

    group('Multiple instances', () {
      test('creates independent instances', () {
        final json1 = <String, dynamic>{...baseJson, 'provider': 'github'};
        final json2 = <String, dynamic>{...baseJson, 'provider': 'gitlab'};

        final model1 = IdentitySummaryModel.fromJson(json1);
        final model2 = IdentitySummaryModel.fromJson(json2);

        expect(model1.provider, 'github');
        expect(model2.provider, 'gitlab');
      });
    });

    group('JSON round-trip', () {
      test('preserves all data through toEntity', () {
        final model = IdentitySummaryModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.id, model.id);
        expect(entity.provider, model.provider);
        expect(entity.subject, model.subject);
        expect(entity.scopes, model.scopes);
      });
    });

    group('Const constructor', () {
      test('supports const instantiation', () {
        final model = IdentitySummaryModel(
          id: 'identity_123',
          provider: 'github',
          subject: 'octocat',
          scopes: const [],
          connectedAt: testConnectedAt,
          expiresAt: null,
        );
        expect(model.provider, 'github');
      });
    });
  });
}

UserServiceSubscriptionModel _createSubscription() {
  return UserServiceSubscriptionModel(
    id: 'sub_123',
    providerId: 'github',
    identityId: 'user_123',
    status: SubscriptionStatus.active,
    scopeGrants: const ['read', 'write'],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
  );
}

IdentitySummaryModel _createIdentity() {
  return IdentitySummaryModel(
    id: 'identity_123',
    provider: 'github',
    subject: 'octocat',
    scopes: const ['user:email', 'repo'],
    connectedAt: DateTime(2024, 1, 1, 10, 0, 0),
    expiresAt: DateTime(2025, 1, 1, 10, 0, 0),
  );
}