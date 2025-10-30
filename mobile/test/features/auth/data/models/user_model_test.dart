import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/auth/data/models/user_model.dart';
import 'package:area/features/auth/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    const testId = 'user-123';
    const testEmail = 'test@example.com';
    final testCreatedAt = DateTime(2024, 1, 1, 10, 30);
    final testUpdatedAt = DateTime(2024, 1, 2, 15, 45);
    final testLastLoginAt = DateTime(2024, 1, 3, 8, 20);

    group('Constructor', () {
      test('creates instance with all parameters', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
          status: 'active',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastLoginAt: testLastLoginAt,
        );

        expect(model.id, testId);
        expect(model.email, testEmail);
        expect(model.status, 'active');
        expect(model.createdAt, testCreatedAt);
        expect(model.updatedAt, testUpdatedAt);
        expect(model.lastLoginAt, testLastLoginAt);
      });

      test('creates instance with minimal parameters', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
        );

        expect(model.id, testId);
        expect(model.email, testEmail);
        expect(model.status, isNull);
        expect(model.createdAt, isNull);
        expect(model.updatedAt, isNull);
        expect(model.lastLoginAt, isNull);
      });
    });

    group('fromJson', () {
      test('creates model from valid JSON with all fields', () {
        final json = {
          'id': testId,
          'email': testEmail,
          'status': 'active',
          'createdAt': '2024-01-01T10:30:00Z',
          'updatedAt': '2024-01-02T15:45:00Z',
          'lastLoginAt': '2024-01-03T08:20:00Z',
        };

        final model = UserModel.fromJson(json);

        expect(model.id, testId);
        expect(model.email, testEmail);
        expect(model.status, 'active');
        expect(model.createdAt, isNotNull);
        expect(model.updatedAt, isNotNull);
        expect(model.lastLoginAt, isNotNull);
      });

      test('creates model from JSON with minimal fields', () {
        final json = {
          'id': testId,
          'email': testEmail,
        };

        final model = UserModel.fromJson(json);

        expect(model.id, testId);
        expect(model.email, testEmail);
        expect(model.status, isNull);
        expect(model.createdAt, isNull);
        expect(model.updatedAt, isNull);
        expect(model.lastLoginAt, isNull);
      });

      test('throws when id is missing', () {
        final json = {
          'email': testEmail,
        };

        expect(() => UserModel.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('throws when email is missing', () {
        final json = {
          'id': testId,
        };

        expect(() => UserModel.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('parses datetime strings correctly', () {
        final json = {
          'id': testId,
          'email': testEmail,
          'createdAt': '2024-01-01T10:30:00Z',
        };

        final model = UserModel.fromJson(json);

        expect(model.createdAt?.year, 2024);
        expect(model.createdAt?.month, 1);
        expect(model.createdAt?.day, 1);
      });
    });

    group('toJson', () {
      test('converts model to JSON with all fields', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
          status: 'active',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final json = model.toJson();

        expect(json['id'], testId);
        expect(json['email'], testEmail);
        expect(json['status'], 'active');
        expect(json['createdAt'], isNotNull);
        expect(json['updatedAt'], isNotNull);
        expect(json['lastLoginAt'], isNotNull);
      });

      test('excludes null optional fields from JSON', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
        );

        final json = model.toJson();

        expect(json.containsKey('status'), false);
        expect(json.containsKey('createdAt'), false);
        expect(json.containsKey('updatedAt'), false);
        expect(json.containsKey('lastLoginAt'), false);
      });

      test('includes partial null optional fields in JSON', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
          status: 'active',
        );

        final json = model.toJson();

        expect(json.containsKey('status'), true);
        expect(json.containsKey('createdAt'), false);
      });
    });

    group('toDomain', () {
      test('converts model to domain entity', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
          status: 'active',
          createdAt: testCreatedAt,
        );

        final domainUser = model.toDomain();

        expect(domainUser, isA<User>());
        expect(domainUser.id, testId);
        expect(domainUser.email, testEmail);
      });

      test('discards extra fields when converting to domain', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
          status: 'active',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final domainUser = model.toDomain();

        expect(domainUser.id, testId);
        expect(domainUser.email, testEmail);
      });
    });

    group('JSON Round-trip', () {
      test('converts to JSON and back without data loss', () {
        final original = UserModel(
          id: testId,
          email: testEmail,
          status: 'active',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastLoginAt: testLastLoginAt,
        );

        final json = original.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.status, original.status);
      });
    });

    group('Inheritance', () {
      test('extends User entity', () {
        final model = UserModel(
          id: testId,
          email: testEmail,
        );

        expect(model, isA<User>());
      });

      test('can be used as User', () {
        final User model = UserModel(
          id: testId,
          email: testEmail,
        );

        expect(model.id, testId);
        expect(model.email, testEmail);
      });
    });
  });
}