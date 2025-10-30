import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/auth/data/models/auth_response_model.dart';
import 'package:area/features/auth/data/models/user_model.dart';

void main() {
  group('AuthResponseModel', () {
    late UserModel testUser;
    late AuthResponseModel authResponse;

    setUp(() {
      testUser = const UserModel(
        id: 'user-123',
        email: 'test@example.com',
        status: 'active',
      );
      authResponse = AuthResponseModel(user: testUser);
    });

    group('Constructor', () {
      test('creates instance with user', () {
        expect(authResponse.user, testUser);
      });
    });

    group('fromJson', () {
      test('creates model from valid JSON', () {
        final json = {
          'user': {
            'id': 'user-123',
            'email': 'test@example.com',
            'status': 'active',
          }
        };

        final model = AuthResponseModel.fromJson(json);

        expect(model.user.id, 'user-123');
        expect(model.user.email, 'test@example.com');
        expect(model.user.status, 'active');
      });

      test('creates model with nested user data', () {
        final json = {
          'user': {
            'id': 'user-456',
            'email': 'another@example.com',
            'status': 'inactive',
            'createdAt': '2024-01-01T10:00:00Z',
            'updatedAt': '2024-01-02T15:00:00Z',
          }
        };

        final model = AuthResponseModel.fromJson(json);

        expect(model.user.id, 'user-456');
        expect(model.user.email, 'another@example.com');
        expect(model.user.status, 'inactive');
        expect(model.user.createdAt, isNotNull);
      });

      test('throws when user data is missing', () {
        final json = <String, dynamic>{};

        expect(() => AuthResponseModel.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws when user is not a map', () {
        final json = {
          'user': 'invalid'
        };

        expect(() => AuthResponseModel.fromJson(json), throwsA(isA<TypeError>()));
      });
    });

    group('toJson', () {
      test('converts model to JSON', () {
        final json = authResponse.toJson();

        expect(json['user'], isNotNull);
        expect(json['user']['id'], 'user-123');
        expect(json['user']['email'], 'test@example.com');
      });

      test('properly serializes nested user object', () {
        final testUserWithDates = UserModel(
          id: 'user-789',
          email: 'nested@example.com',
          status: 'active',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );
        final response = AuthResponseModel(user: testUserWithDates);

        final json = response.toJson();

        expect(json['user']['id'], 'user-789');
        expect(json['user']['email'], 'nested@example.com');
        expect(json['user']['createdAt'], isNotNull);
      });
    });

    group('JSON Round-trip', () {
      test('converts to JSON and back preserves data', () {
        final json = authResponse.toJson();
        final restored = AuthResponseModel.fromJson(json);

        expect(restored.user.id, authResponse.user.id);
        expect(restored.user.email, authResponse.user.email);
      });

      test('round-trip with full user data', () {
        final userWithAllData = UserModel(
          id: 'user-full',
          email: 'full@example.com',
          status: 'active',
          createdAt: DateTime(2024, 1, 1, 10, 30),
          updatedAt: DateTime(2024, 1, 2, 15, 45),
          lastLoginAt: DateTime(2024, 1, 3, 8, 20),
        );
        final originalResponse = AuthResponseModel(user: userWithAllData);

        final json = originalResponse.toJson();
        final restored = AuthResponseModel.fromJson(json);

        expect(restored.user.id, originalResponse.user.id);
        expect(restored.user.email, originalResponse.user.email);
        expect(restored.user.status, originalResponse.user.status);
      });
    });

    group('Multiple responses', () {
      test('creates multiple different responses', () {
        final user1 = const UserModel(id: 'user-1', email: 'user1@example.com');
        final user2 = const UserModel(id: 'user-2', email: 'user2@example.com');

        final response1 = AuthResponseModel(user: user1);
        final response2 = AuthResponseModel(user: user2);

        expect(response1.user.id, 'user-1');
        expect(response2.user.id, 'user-2');
      });
    });

    group('Edge cases', () {
      test('handles user with empty string fields', () {
        final json = {
          'user': {
            'id': '',
            'email': '',
          }
        };

        final model = AuthResponseModel.fromJson(json);

        expect(model.user.id, '');
        expect(model.user.email, '');
      });

      test('handles user with special characters in email', () {
        final json = {
          'user': {
            'id': 'user-123',
            'email': 'test+special@sub.example.com',
          }
        };

        final model = AuthResponseModel.fromJson(json);

        expect(model.user.email, 'test+special@sub.example.com');
      });
    });
  });
}