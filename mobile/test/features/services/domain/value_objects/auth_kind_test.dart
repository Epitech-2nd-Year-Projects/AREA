import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/domain/value_objects/auth_kind.dart';

void main() {
  group('AuthKind', () {
    group('Enum values', () {
      test('has all required values', () {
        expect(AuthKind.values.length, 3);
        expect(AuthKind.values, contains(AuthKind.none));
        expect(AuthKind.values, contains(AuthKind.oauth2));
        expect(AuthKind.values, contains(AuthKind.apikey));
      });

      test('values have correct string representation', () {
        expect(AuthKind.none.value, 'none');
        expect(AuthKind.oauth2.value, 'oauth2');
        expect(AuthKind.apikey.value, 'apikey');
      });
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(AuthKind.fromString('none'), AuthKind.none);
        expect(AuthKind.fromString('oauth2'), AuthKind.oauth2);
        expect(AuthKind.fromString('apikey'), AuthKind.apikey);
      });

      test('defaults to none for unknown strings', () {
        expect(AuthKind.fromString('unknown'), AuthKind.none);
        expect(AuthKind.fromString('bearer'), AuthKind.none);
        expect(AuthKind.fromString(''), AuthKind.none);
      });

      test('is case-sensitive', () {
        expect(AuthKind.fromString('OAuth2'), AuthKind.none);
        expect(AuthKind.fromString('OAUTH2'), AuthKind.none);
        expect(AuthKind.fromString('OAuth2'.toLowerCase()), AuthKind.oauth2);
      });

      test('handles whitespace', () {
        expect(AuthKind.fromString(' oauth2'), AuthKind.none);
        expect(AuthKind.fromString('oauth2 '), AuthKind.none);
        expect(AuthKind.fromString(' oauth2 '), AuthKind.none);
      });

      test('returns correct enum after multiple calls', () {
        final first = AuthKind.fromString('oauth2');
        final second = AuthKind.fromString('oauth2');
        expect(first, second);
      });
    });

    group('requiresOAuth getter', () {
      test('returns true for oauth2', () {
        expect(AuthKind.oauth2.requiresOAuth, true);
      });

      test('returns false for none and apikey', () {
        expect(AuthKind.none.requiresOAuth, false);
        expect(AuthKind.apikey.requiresOAuth, false);
      });

      test('works correctly for all enum values', () {
        final expectedResults = {
          AuthKind.none: false,
          AuthKind.oauth2: true,
          AuthKind.apikey: false,
        };

        for (final kind in AuthKind.values) {
          expect(kind.requiresOAuth, expectedResults[kind]);
        }
      });
    });

    group('requiresApiKey getter', () {
      test('returns true for apikey', () {
        expect(AuthKind.apikey.requiresApiKey, true);
      });

      test('returns false for none and oauth2', () {
        expect(AuthKind.none.requiresApiKey, false);
        expect(AuthKind.oauth2.requiresApiKey, false);
      });

      test('works correctly for all enum values', () {
        final expectedResults = {
          AuthKind.none: false,
          AuthKind.oauth2: false,
          AuthKind.apikey: true,
        };

        for (final kind in AuthKind.values) {
          expect(kind.requiresApiKey, expectedResults[kind]);
        }
      });
    });

    group('requiresAuth getter', () {
      test('returns false only for none', () {
        expect(AuthKind.none.requiresAuth, false);
      });

      test('returns true for oauth2 and apikey', () {
        expect(AuthKind.oauth2.requiresAuth, true);
        expect(AuthKind.apikey.requiresAuth, true);
      });

      test('works correctly for all enum values', () {
        final expectedResults = {
          AuthKind.none: false,
          AuthKind.oauth2: true,
          AuthKind.apikey: true,
        };

        for (final kind in AuthKind.values) {
          expect(kind.requiresAuth, expectedResults[kind]);
        }
      });
    });

    group('Combined getters logic', () {
      test('oauth2 requires oauth but not api key', () {
        expect(AuthKind.oauth2.requiresOAuth, true);
        expect(AuthKind.oauth2.requiresApiKey, false);
        expect(AuthKind.oauth2.requiresAuth, true);
      });

      test('apikey requires api key but not oauth', () {
        expect(AuthKind.apikey.requiresOAuth, false);
        expect(AuthKind.apikey.requiresApiKey, true);
        expect(AuthKind.apikey.requiresAuth, true);
      });

      test('none requires no auth', () {
        expect(AuthKind.none.requiresOAuth, false);
        expect(AuthKind.none.requiresApiKey, false);
        expect(AuthKind.none.requiresAuth, false);
      });
    });

    group('Edge cases', () {
      test('handles null input gracefully', () {
        try {
          final result = AuthKind.fromString('');
          expect(result, AuthKind.none);
        } catch (e) {
          expect(e, isNotNull);
        }
      });

      test('repeated calls with same input are idempotent', () {
        final result1 = AuthKind.fromString('apikey');
        final result2 = AuthKind.fromString('apikey');
        final result3 = AuthKind.fromString('apikey');

        expect(result1, result2);
        expect(result2, result3);
      });

      test('handles each enum value as string correctly', () {
        for (final kind in AuthKind.values) {
          final restored = AuthKind.fromString(kind.value);
          expect(restored, kind);
        }
      });
    });

    group('Comparison', () {
      test('enum values are comparable', () {
        expect(AuthKind.none == AuthKind.none, true);
        expect(AuthKind.oauth2 == AuthKind.apikey, false);
      });

      test('can be used in switch statements', () {
        String describe(AuthKind kind) {
          return switch (kind) {
            AuthKind.none => 'No authentication',
            AuthKind.oauth2 => 'OAuth 2.0',
            AuthKind.apikey => 'API Key',
          };
        }

        expect(describe(AuthKind.oauth2), 'OAuth 2.0');
        expect(describe(AuthKind.apikey), 'API Key');
        expect(describe(AuthKind.none), 'No authentication');
      });
    });
  });
}