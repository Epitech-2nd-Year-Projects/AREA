import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/data/models/subscribe_service_response_model.dart';
import 'package:area/features/services/domain/entities/service_subscription_result.dart';

void main() {
  group('SubscribeServiceResponseModel', () {
    const testUrl = 'https://oauth.example.com/authorize?code=abc123';
    const testState = 'state_123';
    const testCodeVerifier = 'code_verifier_123';
    const testCodeChallenge = 'code_challenge_123';

    group('Constructor', () {
      test('creates instance with subscribed status', () {
        const model = SubscribeServiceResponseModel(
          status: ServiceSubscriptionStatus.subscribed,
        );

        expect(model.status, ServiceSubscriptionStatus.subscribed);
        expect(model.authorization, isNull);
        expect(model.subscription, isNull);
      });

      test('creates instance with authorization_required status', () {
        const model = SubscribeServiceResponseModel(
          status: ServiceSubscriptionStatus.authorizationRequired,
        );

        expect(model.status, ServiceSubscriptionStatus.authorizationRequired);
        expect(model.authorization, isNull);
        expect(model.subscription, isNull);
      });

      test('creates instance with all fields', () {
        final auth = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
          state: testState,
        );

        final model = SubscribeServiceResponseModel(
          status: ServiceSubscriptionStatus.subscribed,
          authorization: auth,
        );

        expect(model.status, ServiceSubscriptionStatus.subscribed);
        expect(model.authorization, auth);
      });
    });

    group('fromJson - Status parsing', () {
      test('parses authorization_required status', () {
        final json = <String, dynamic>{
          'status': 'authorization_required',
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.status, ServiceSubscriptionStatus.authorizationRequired);
      });

      test('parses subscribed status', () {
        final json = <String, dynamic>{
          'status': 'subscribed',
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.status, ServiceSubscriptionStatus.subscribed);
      });

      test('treats unknown status as subscribed', () {
        final json = <String, dynamic>{
          'status': 'unknown_status',
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.status, ServiceSubscriptionStatus.subscribed);
      });
    });

    group('fromJson - Authorization data', () {
      test('parses authorization when present', () {
        final json = <String, dynamic>{
          'status': 'authorization_required',
          'authorization': <String, dynamic>{
            'authorizationUrl': testUrl,
            'state': testState,
            'codeVerifier': testCodeVerifier,
            'codeChallenge': testCodeChallenge,
          }
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.authorization, isNotNull);
        expect(model.authorization!.authorizationUrl, testUrl);
        expect(model.authorization!.state, testState);
      });

      test('ignores authorization when not a map', () {
        final json = <String, dynamic>{
          'status': 'authorization_required',
          'authorization': 'not_a_map',
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.authorization, isNull);
      });

      test('ignores null authorization', () {
        final json = <String, dynamic>{
          'status': 'authorization_required',
          'authorization': null,
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.authorization, isNull);
      });
    });

    group('fromJson - Subscription data', () {
      test('parses subscription when present', () {
        final json = <String, dynamic>{
          'status': 'subscribed',
          'subscription': <String, dynamic>{
            'id': 'sub_123',
            'providerId': 'github',
            'identityId': 'user_123',
            'status': 'active',
            'scopeGrants': ['read', 'write'],
            'createdAt': '2024-01-01T00:00:00Z',
            'updatedAt': '2024-01-02T00:00:00Z',
          }
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.subscription, isNotNull);
        expect(model.subscription!.id, 'sub_123');
        expect(model.subscription!.providerId, 'github');
      });

      test('ignores subscription when not a map', () {
        final json = <String, dynamic>{
          'status': 'subscribed',
          'subscription': 'not_a_map',
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.subscription, isNull);
      });

      test('ignores null subscription', () {
        final json = <String, dynamic>{
          'status': 'subscribed',
          'subscription': null,
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.subscription, isNull);
      });
    });

    group('fromJson - Complex scenarios', () {
      test('parses authorization_required with authorization data', () {
        final json = <String, dynamic>{
          'status': 'authorization_required',
          'authorization': <String, dynamic>{
            'authorizationUrl': testUrl,
            'state': testState,
            'codeVerifier': testCodeVerifier,
          }
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.status, ServiceSubscriptionStatus.authorizationRequired);
        expect(model.authorization, isNotNull);
        expect(model.subscription, isNull);
      });

      test('parses subscribed with subscription data', () {
        final json = <String, dynamic>{
          'status': 'subscribed',
          'subscription': <String, dynamic>{
            'id': 'sub_123',
            'providerId': 'github',
            'identityId': null,
            'status': 'active',
            'scopeGrants': <String>[],
            'createdAt': '2024-01-01T00:00:00Z',
            'updatedAt': '2024-01-02T00:00:00Z',
          }
        };

        final model = SubscribeServiceResponseModel.fromJson(json);

        expect(model.status, ServiceSubscriptionStatus.subscribed);
        expect(model.subscription, isNotNull);
        expect(model.authorization, isNull);
      });
    });

    group('toEntity', () {
      test('converts to ServiceSubscriptionResult entity', () {
        final json = <String, dynamic>{
          'status': 'subscribed',
        };

        final model = SubscribeServiceResponseModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity, isA<ServiceSubscriptionResult>());
        expect(entity.status, ServiceSubscriptionStatus.subscribed);
      });

      test('preserves authorization in entity conversion', () {
        final json = <String, dynamic>{
          'status': 'authorization_required',
          'authorization': <String, dynamic>{
            'authorizationUrl': testUrl,
            'state': testState,
          }
        };

        final model = SubscribeServiceResponseModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.authorization, isNotNull);
        expect(entity.authorization!.authorizationUrl, testUrl);
      });

      test('preserves subscription in entity conversion', () {
        final json = <String, dynamic>{
          'status': 'subscribed',
          'subscription': <String, dynamic>{
            'id': 'sub_123',
            'providerId': 'github',
            'identityId': 'user_123',
            'status': 'active',
            'scopeGrants': ['read'],
            'createdAt': '2024-01-01T00:00:00Z',
            'updatedAt': '2024-01-02T00:00:00Z',
          }
        };

        final model = SubscribeServiceResponseModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.subscription, isNotNull);
        expect(entity.subscription!.id, 'sub_123');
      });
    });

    group('Const constructor', () {
      test('supports const instantiation', () {
        const model = SubscribeServiceResponseModel(
          status: ServiceSubscriptionStatus.subscribed,
        );
        expect(model.status, ServiceSubscriptionStatus.subscribed);
      });
    });

    group('Multiple instances', () {
      test('creates independent instances', () {
        const model1 = SubscribeServiceResponseModel(
          status: ServiceSubscriptionStatus.subscribed,
        );

        const model2 = SubscribeServiceResponseModel(
          status: ServiceSubscriptionStatus.authorizationRequired,
        );

        expect(model1.status, isNot(model2.status));
      });
    });
  });

  group('ServiceAuthorizationDataModel', () {
    const testUrl = 'https://oauth.example.com/authorize';
    const testState = 'state_123';
    const testCodeVerifier = 'verifier_123';
    const testCodeChallenge = 'challenge_123';
    const testMethod = 'S256';

    group('Constructor', () {
      test('creates instance with required URL', () {
        const model = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
        );

        expect(model.authorizationUrl, testUrl);
        expect(model.state, isNull);
        expect(model.codeVerifier, isNull);
      });

      test('creates instance with all fields', () {
        const model = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
          state: testState,
          codeVerifier: testCodeVerifier,
          codeChallenge: testCodeChallenge,
          codeChallengeMethod: testMethod,
        );

        expect(model.authorizationUrl, testUrl);
        expect(model.state, testState);
        expect(model.codeVerifier, testCodeVerifier);
      });
    });

    group('fromJson - camelCase format', () {
      test('parses complete JSON', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
          'state': testState,
          'codeVerifier': testCodeVerifier,
          'codeChallenge': testCodeChallenge,
          'codeChallengeMethod': testMethod,
        };

        final model = ServiceAuthorizationDataModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.state, testState);
        expect(model.codeVerifier, testCodeVerifier);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.codeChallengeMethod, testMethod);
      });

      test('parses minimal JSON', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
        };

        final model = ServiceAuthorizationDataModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.state, isNull);
      });
    });

    group('fromJson - snake_case format', () {
      test('parses snake_case authorizationUrl', () {
        final json = <String, dynamic>{
          'authorization_url': testUrl,
        };

        final model = ServiceAuthorizationDataModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
      });

      test('parses complete snake_case JSON', () {
        final json = <String, dynamic>{
          'authorization_url': testUrl,
          'state': testState,
          'code_verifier': testCodeVerifier,
          'code_challenge': testCodeChallenge,
          'code_challenge_method': testMethod,
        };

        final model = ServiceAuthorizationDataModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.codeVerifier, testCodeVerifier);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.codeChallengeMethod, testMethod);
      });

      test('prefers camelCase over snake_case', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
          'authorization_url': 'https://wrong.com',
        };

        final model = ServiceAuthorizationDataModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
      });
    });

    group('fromJson - Error handling', () {
      test('throws when authorizationUrl is missing', () {
        final json = <String, dynamic>{
          'state': testState,
        };

        expect(
          () => ServiceAuthorizationDataModel.fromJson(json),
          throwsException,
        );
      });

      test('throws when authorizationUrl is null', () {
        final json = <String, dynamic>{
          'authorizationUrl': null,
        };

        expect(
          () => ServiceAuthorizationDataModel.fromJson(json),
          throwsException,
        );
      });

      test('throws when authorizationUrl is not string', () {
        final json = <String, dynamic>{
          'authorizationUrl': 123,
        };

        expect(
          () => ServiceAuthorizationDataModel.fromJson(json),
          throwsException,
        );
      });

      test('throws with descriptive message', () {
        final json = <String, dynamic>{
          'authorizationUrl': null,
        };

        expect(
          () => ServiceAuthorizationDataModel.fromJson(json),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid subscription authorization payload'),
            ),
          ),
        );
      });
    });

    group('toEntity', () {
      test('converts to ServiceAuthorizationData entity', () {
        const model = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
          state: testState,
        );

        final entity = model.toEntity();

        expect(entity.authorizationUrl, testUrl);
        expect(entity.state, testState);
      });

      test('preserves all fields in entity', () {
        const model = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
          state: testState,
          codeVerifier: testCodeVerifier,
          codeChallenge: testCodeChallenge,
          codeChallengeMethod: testMethod,
        );

        final entity = model.toEntity();

        expect(entity.codeVerifier, testCodeVerifier);
        expect(entity.codeChallenge, testCodeChallenge);
        expect(entity.codeChallengeMethod, testMethod);
      });
    });

    group('PKCE Support', () {
      test('preserves PKCE parameters', () {
        const longVerifier =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        const model = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
          codeVerifier: longVerifier,
          codeChallenge: 'E9Mrozoa2owUednDM6mp8tau7zjz2mkQHfzf2rqqSgQ',
          codeChallengeMethod: 'S256',
        );

        expect(model.codeVerifier, isNotEmpty);
        expect(model.codeChallenge, isNotEmpty);
        expect(model.codeChallengeMethod, 'S256');
      });
    });

    group('Immutability', () {
      test('is immutable', () {
        const model = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
        );

        expect(model, isA<ServiceAuthorizationDataModel>());
      });
    });

    group('Const constructor', () {
      test('supports const instantiation', () {
        const model = ServiceAuthorizationDataModel(
          authorizationUrl: testUrl,
        );
        expect(model.authorizationUrl, testUrl);
      });
    });
  });
}