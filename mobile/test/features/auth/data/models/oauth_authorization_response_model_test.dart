import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/auth/data/models/oauth_authorization_response_model.dart';

void main() {
  group('OAuthAuthorizationResponseModel', () {
    const testUrl = 'https://example.com/authorize?code=abc123';
    const testState = 'test_state_123';
    const testCodeVerifier = 'test_code_verifier';
    const testCodeChallenge = 'test_code_challenge';
    const testChallengeMethod = 'S256';

    group('Constructor', () {
      test('creates instance with required authorizationUrl only', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
        );

        expect(model.authorizationUrl, testUrl);
        expect(model.state, isNull);
        expect(model.codeVerifier, isNull);
        expect(model.codeChallenge, isNull);
        expect(model.codeChallengeMethod, isNull);
      });

      test('creates instance with all parameters', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          state: testState,
          codeVerifier: testCodeVerifier,
          codeChallenge: testCodeChallenge,
          codeChallengeMethod: testChallengeMethod,
        );

        expect(model.authorizationUrl, testUrl);
        expect(model.state, testState);
        expect(model.codeVerifier, testCodeVerifier);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.codeChallengeMethod, testChallengeMethod);
      });

      test('creates instance with partial optional parameters', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          state: testState,
          codeChallenge: testCodeChallenge,
        );

        expect(model.authorizationUrl, testUrl);
        expect(model.state, testState);
        expect(model.codeVerifier, isNull);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.codeChallengeMethod, isNull);
      });
    });

    group('fromJson - Standard camelCase format', () {
      test('parses complete JSON with camelCase', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
          'state': testState,
          'codeVerifier': testCodeVerifier,
          'codeChallenge': testCodeChallenge,
          'codeChallengeMethod': testChallengeMethod,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.state, testState);
        expect(model.codeVerifier, testCodeVerifier);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.codeChallengeMethod, testChallengeMethod);
      });

      test('parses JSON with only required field', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.state, isNull);
        expect(model.codeVerifier, isNull);
        expect(model.codeChallenge, isNull);
        expect(model.codeChallengeMethod, isNull);
      });

      test('parses JSON with optional fields', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
          'state': testState,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.state, testState);
        expect(model.codeVerifier, isNull);
      });
    });

    group('fromJson - snake_case format', () {
      test('parses complete JSON with snake_case', () {
        final json = <String, dynamic>{
          'authorization_url': testUrl,
          'state': testState,
          'code_verifier': testCodeVerifier,
          'code_challenge': testCodeChallenge,
          'code_challenge_method': testChallengeMethod,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.state, testState);
        expect(model.codeVerifier, testCodeVerifier);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.codeChallengeMethod, testChallengeMethod);
      });

      test('parses JSON with snake_case authorizationUrl', () {
        final json = <String, dynamic>{
          'authorization_url': testUrl,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
      });

      test('handles mixed snake_case optional fields', () {
        final json = <String, dynamic>{
          'authorization_url': testUrl,
          'code_verifier': testCodeVerifier,
          'code_challenge': testCodeChallenge,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.codeVerifier, testCodeVerifier);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.state, isNull);
        expect(model.codeChallengeMethod, isNull);
      });
    });

    group('fromJson - Field priority', () {
      test('prefers camelCase over snake_case', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
          'authorization_url': 'https://wrong.com',
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
      });

      test('uses snake_case fallback when camelCase missing', () {
        final json = <String, dynamic>{
          'authorization_url': testUrl,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
      });

      test('handles mixed case fields', () {
        final json = <String, dynamic>{
          'authorizationUrl': testUrl,
          'code_verifier': testCodeVerifier,
          'codeChallenge': testCodeChallenge,
          'code_challenge_method': testChallengeMethod,
        };

        final model = OAuthAuthorizationResponseModel.fromJson(json);

        expect(model.authorizationUrl, testUrl);
        expect(model.codeVerifier, testCodeVerifier);
        expect(model.codeChallenge, testCodeChallenge);
        expect(model.codeChallengeMethod, testChallengeMethod);
      });
    });

    group('fromJson - Error cases', () {
      test('throws exception when authorizationUrl is missing', () {
        final json = <String, dynamic>{
          'state': testState,
        };

        expect(
          () => OAuthAuthorizationResponseModel.fromJson(json),
          throwsException,
        );
      });

      test('throws exception when authorizationUrl is null', () {
        final json = <String, dynamic>{
          'authorizationUrl': null,
        };

        expect(
          () => OAuthAuthorizationResponseModel.fromJson(json),
          throwsException,
        );
      });

      test('throws exception when authorizationUrl is not string', () {
        final json = <String, dynamic>{
          'authorizationUrl': 123,
        };

        expect(
          () => OAuthAuthorizationResponseModel.fromJson(json),
          throwsException,
        );
      });

      test('throws exception with descriptive message', () {
        final json = <String, dynamic>{
          'authorizationUrl': null,
        };

        expect(
          () => OAuthAuthorizationResponseModel.fromJson(json),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid OAuth authorization response'),
            ),
          ),
        );
      });
    });

    group('toJson', () {
      test('converts model to JSON with all fields', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          state: testState,
          codeVerifier: testCodeVerifier,
          codeChallenge: testCodeChallenge,
          codeChallengeMethod: testChallengeMethod,
        );

        final json = model.toJson();

        expect(json['authorizationUrl'], testUrl);
        expect(json['state'], testState);
        expect(json['codeVerifier'], testCodeVerifier);
        expect(json['codeChallenge'], testCodeChallenge);
        expect(json['codeChallengeMethod'], testChallengeMethod);
      });

      test('excludes null optional fields from JSON', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
        );

        final json = model.toJson();

        expect(json.containsKey('authorizationUrl'), true);
        expect(json.containsKey('state'), false);
        expect(json.containsKey('codeVerifier'), false);
        expect(json.containsKey('codeChallenge'), false);
        expect(json.containsKey('codeChallengeMethod'), false);
      });

      test('includes only non-null optional fields', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          state: testState,
          codeChallenge: testCodeChallenge,
        );

        final json = model.toJson();

        expect(json.containsKey('authorizationUrl'), true);
        expect(json.containsKey('state'), true);
        expect(json.containsKey('codeChallenge'), true);
        expect(json.containsKey('codeVerifier'), false);
        expect(json.containsKey('code_challengeMethod'), false);
      });
    });

    group('URL handling', () {
      test('preserves complex URLs with query parameters', () {
        const complexUrl =
            'https://oauth.provider.com/auth?client_id=abc&response_type=code&scope=profile%20email&redirect_uri=https://app.com/callback';

        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: complexUrl,
        );

        expect(model.authorizationUrl, complexUrl);
      });

      test('preserves URLs with fragments', () {
        const urlWithFragment = 'https://example.com/auth#state=123&nonce=456';

        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: urlWithFragment,
        );

        expect(model.authorizationUrl, urlWithFragment);
      });

      test('handles roundtrip with complex URL', () {
        const complexUrl =
            'https://oauth.example.com/authorize?client_id=test&redirect_uri=https://myapp.com/callback&response_type=code';

        const originalModel = OAuthAuthorizationResponseModel(
          authorizationUrl: complexUrl,
        );

        final json = originalModel.toJson();
        final restored = OAuthAuthorizationResponseModel.fromJson(json);

        expect(restored.authorizationUrl, complexUrl);
      });
    });

    group('PKCE flow support', () {
      test('supports complete PKCE flow parameters', () {
        const longVerifier =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          state: testState,
          codeVerifier: longVerifier,
          codeChallenge:
              'E9Mrozoa2owUednDM6mp8tau7zjz2mkQHfzf2rqqSgQ',
          codeChallengeMethod: 'S256',
        );

        expect(model.codeVerifier, isNotEmpty);
        expect(model.codeChallenge, isNotEmpty);
        expect(model.codeChallengeMethod, 'S256');
      });

      test('handles plain PKCE (code_challenge_method: plain)', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          codeVerifier: 'test_verifier',
          codeChallenge: 'test_verifier',
          codeChallengeMethod: 'plain',
        );

        expect(model.codeVerifier, model.codeChallenge);
        expect(model.codeChallengeMethod, 'plain');
      });
    });

    group('Multiple instances', () {
      test('creates independent instances', () {
        const model1 = OAuthAuthorizationResponseModel(
          authorizationUrl: 'https://provider1.com/auth',
          state: 'state1',
        );

        const model2 = OAuthAuthorizationResponseModel(
          authorizationUrl: 'https://provider2.com/auth',
          state: 'state2',
        );

        expect(model1.authorizationUrl, isNot(model2.authorizationUrl));
        expect(model1.state, isNot(model2.state));
      });
    });

    group('JSON round-trip', () {
      test('complete roundtrip preserves all data', () {
        const original = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          state: testState,
          codeVerifier: testCodeVerifier,
          codeChallenge: testCodeChallenge,
          codeChallengeMethod: testChallengeMethod,
        );

        final json = original.toJson();
        final restored = OAuthAuthorizationResponseModel.fromJson(json);

        expect(restored.authorizationUrl, original.authorizationUrl);
        expect(restored.state, original.state);
        expect(restored.codeVerifier, original.codeVerifier);
        expect(restored.codeChallenge, original.codeChallenge);
        expect(restored.codeChallengeMethod, original.codeChallengeMethod);
      });
    });

    group('Const constructor', () {
      test('supports const instantiation', () {
        const model = OAuthAuthorizationResponseModel(
          authorizationUrl: testUrl,
          state: testState,
        );
        expect(model.authorizationUrl, testUrl);
      });
    });
  });
}