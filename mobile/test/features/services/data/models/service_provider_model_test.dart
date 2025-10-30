import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/data/models/service_provider_model.dart';
import 'package:area/features/services/domain/value_objects/service_category.dart';
import 'package:area/features/services/domain/value_objects/auth_kind.dart';
import 'package:area/features/services/domain/entities/service_provider.dart';

void main() {
  group('ServiceProviderModel', () {
    final testCreatedAt = DateTime(2024, 1, 1);
    final testUpdatedAt = DateTime(2024, 1, 2);

    group('Constructor', () {
      test('creates instance with all parameters', () {
        final model = ServiceProviderModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
          category: ServiceCategory.development,
          oauthType: AuthKind.oauth2,
          authConfig: const {'clientId': 'abc123'},
          isEnabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(model.id, 'github');
        expect(model.name, 'github');
        expect(model.displayName, 'GitHub');
        expect(model.category, ServiceCategory.development);
        expect(model.oauthType, AuthKind.oauth2);
        expect(model.authConfig, {'clientId': 'abc123'});
        expect(model.isEnabled, true);
      });
    });

    group('fromJson - Standard format', () {
      test('creates model from complete JSON', () {
        final json = <String, dynamic>{
          'id': 'github',
          'name': 'github',
          'displayName': 'GitHub',
          'category': 'development',
          'oauthType': 'oauth2',
          'authConfig': <String, dynamic>{'clientId': 'abc'},
          'isEnabled': true,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-02T00:00:00Z',
        };

        final model = ServiceProviderModel.fromJson(json);

        expect(model.id, 'github');
        expect(model.name, 'github');
        expect(model.displayName, 'GitHub');
        expect(model.category, ServiceCategory.development);
        expect(model.oauthType, AuthKind.oauth2);
        expect(model.isEnabled, true);
      });

      test('handles all service categories', () {
        const categories = [
          ('social', ServiceCategory.social),
          ('productivity', ServiceCategory.productivity),
          ('communication', ServiceCategory.communication),
          ('storage', ServiceCategory.storage),
          ('development', ServiceCategory.development),
          ('other', ServiceCategory.other),
        ];

        for (final (categoryStr, expectedCategory) in categories) {
          final json = <String, dynamic>{
            'id': 'service',
            'name': 'service',
            'displayName': 'Service',
            'category': categoryStr,
            'oauthType': 'oauth2',
            'authConfig': <String, dynamic>{},
            'isEnabled': true,
            'createdAt': '2024-01-01T00:00:00Z',
            'updatedAt': '2024-01-02T00:00:00Z',
          };

          final model = ServiceProviderModel.fromJson(json);
          expect(model.category, expectedCategory);
        }
      });
    });

    group('fromJson - Alternative formats', () {
      test('handles snake_case field names', () {
        final json = <String, dynamic>{
          'id': 'service',
          'name': 'service',
          'display_name': 'Service',
          'category': 'productivity',
          'auth_type': 'oauth2',
          'auth_config': <String, dynamic>{},
          'is_enabled': true,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-02T00:00:00Z',
        };

        final model = ServiceProviderModel.fromJson(json);

        expect(model.displayName, 'Service');
        expect(model.oauthType, AuthKind.oauth2);
        expect(model.isEnabled, true);
      });

      test('uses slug as fallback for id', () {
        final json = <String, dynamic>{
          'slug': 'github',
          'name': 'github',
          'displayName': 'GitHub',
          'category': 'development',
          'oauthType': 'oauth2',
          'authConfig': <String, dynamic>{},
          'isEnabled': true,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-02T00:00:00Z',
        };

        final model = ServiceProviderModel.fromJson(json);

        expect(model.id, 'github');
      });

      test('uses authType as fallback for oauthType', () {
        final json = <String, dynamic>{
          'id': 'service',
          'name': 'service',
          'displayName': 'Service',
          'category': 'productivity',
          'authType': 'apikey',
          'authConfig': <String, dynamic>{},
          'isEnabled': true,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-02T00:00:00Z',
        };

        final model = ServiceProviderModel.fromJson(json);

        expect(model.oauthType, AuthKind.apikey);
      });
    });

    group('fromJson - Missing fields', () {
      test('uses defaults for missing optional fields', () {
        final json = <String, dynamic>{
          'id': 'service',
          'name': 'service',
          'displayName': 'Service',
          'category': 'productivity',
          'oauthType': 'oauth2',
        };

        final model = ServiceProviderModel.fromJson(json);

        expect(model.authConfig, {});
        expect(model.isEnabled, true);
      });

      test('uses current time for missing dates', () {
        final beforeCreation = DateTime.now();
        final json = <String, dynamic>{
          'id': 'service',
          'name': 'service',
          'displayName': 'Service',
          'category': 'productivity',
          'oauthType': 'oauth2',
          'authConfig': <String, dynamic>{},
          'isEnabled': true,
        };

        final model = ServiceProviderModel.fromJson(json);
        final afterCreation = DateTime.now();

        expect(model.createdAt.isAfter(beforeCreation), true);
        expect(model.updatedAt.isBefore(afterCreation.add(Duration(seconds: 1))), true);
      });

      test('defaults to empty string for missing id, name, displayName', () {
        final json = <String, dynamic>{
          'category': 'productivity',
          'oauthType': 'oauth2',
          'authConfig': <String, dynamic>{},
          'isEnabled': true,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-02T00:00:00Z',
        };

        final model = ServiceProviderModel.fromJson(json);

        expect(model.id, '');
        expect(model.name, '');
        expect(model.displayName, '');
      });

      test('defaults to other category for missing category', () {
        final json = <String, dynamic>{
          'id': 'service',
          'name': 'service',
          'displayName': 'Service',
          'oauthType': 'oauth2',
          'authConfig': <String, dynamic>{},
          'isEnabled': true,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-02T00:00:00Z',
        };

        final model = ServiceProviderModel.fromJson(json);

        expect(model.category, ServiceCategory.other);
      });
    });

    group('fromServiceName', () {
      test('creates model from service name with social category', () {
        final model = ServiceProviderModel.fromServiceName('Facebook');

        expect(model.displayName, 'Facebook');
        expect(model.category, ServiceCategory.social);
        expect(model.isEnabled, true);
      });

      test('detects multiple social services', () {
        final testCases = [
          ('Facebook', ServiceCategory.social),
          ('Twitter', ServiceCategory.social),
          ('Instagram', ServiceCategory.social),
        ];

        for (final (name, expectedCategory) in testCases) {
          final model = ServiceProviderModel.fromServiceName(name);
          expect(model.category, expectedCategory, reason: 'Failed for $name');
        }
      });

      test('detects storage services', () {
        final model1 = ServiceProviderModel.fromServiceName('Google Drive');
        expect(model1.category, ServiceCategory.storage);

        final model2 = ServiceProviderModel.fromServiceName('Dropbox');
        expect(model2.category, ServiceCategory.storage);
      });

      test('detects communication services', () {
        final model1 = ServiceProviderModel.fromServiceName('Gmail');
        expect(model1.category, ServiceCategory.communication);

        final model2 = ServiceProviderModel.fromServiceName('Outlook');
        expect(model2.category, ServiceCategory.communication);
      });

      test('detects productivity services', () {
        final model1 = ServiceProviderModel.fromServiceName('Google Calendar');
        expect(model1.category, ServiceCategory.productivity);

        final model2 = ServiceProviderModel.fromServiceName('Notion');
        expect(model2.category, ServiceCategory.productivity);
      });

      test('defaults to other category for unknown services', () {
        final model = ServiceProviderModel.fromServiceName('UnknownService');

        expect(model.category, ServiceCategory.other);
      });

      test('normalizes service name to lowercase id', () {
        final model = ServiceProviderModel.fromServiceName('GitHub');

        expect(model.id, 'github');
        expect(model.name, 'github');
      });

      test('replaces spaces with underscores in id', () {
        final model = ServiceProviderModel.fromServiceName('Google Drive');

        expect(model.id, 'google_drive');
      });

      test('case-insensitive category matching', () {
        final modelLower = ServiceProviderModel.fromServiceName('github');
        final modelUpper = ServiceProviderModel.fromServiceName('GITHUB');
        final modelMixed = ServiceProviderModel.fromServiceName('GiThUb');

        expect(modelLower.category, ServiceCategory.development);
        expect(modelUpper.category, ServiceCategory.development);
        expect(modelMixed.category, ServiceCategory.development);
      });
    });

    group('toEntity', () {
      test('converts model to ServiceProvider entity', () {
        final model = ServiceProviderModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
          category: ServiceCategory.development,
          oauthType: AuthKind.oauth2,
          authConfig: const {},
          isEnabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final entity = model.toEntity();

        expect(entity, isA<ServiceProvider>());
        expect(entity.id, 'github');
        expect(entity.displayName, 'GitHub');
        expect(entity.category, ServiceCategory.development);
      });

      test('preserves all data when converting to entity', () {
        final authConfig = {'clientId': 'abc123', 'scopes': ['read', 'write']};
        final model = ServiceProviderModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
          category: ServiceCategory.development,
          oauthType: AuthKind.oauth2,
          authConfig: authConfig,
          isEnabled: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final entity = model.toEntity();

        expect(entity.authConfig, authConfig);
        expect(entity.isEnabled, false);
        expect(entity.createdAt, testCreatedAt);
      });
    });

    group('formatDisplayName', () {
      test('formats snake_case names correctly', () {
        final model = ServiceProviderModel.fromServiceName('google_drive');
        expect(model.displayName, 'Google Drive');
      });
    });

    group('JSON Round-trip', () {
      test('converts to entity and preserves complete data', () {
        final original = ServiceProviderModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
          category: ServiceCategory.development,
          oauthType: AuthKind.oauth2,
          authConfig: const {'key': 'value'},
          isEnabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final entity = original.toEntity();

        expect(entity.id, original.id);
        expect(entity.name, original.name);
        expect(entity.displayName, original.displayName);
        expect(entity.category, original.category);
      });
    });

    group('Multiple providers', () {
      test('creates different providers independently', () {
        final github = ServiceProviderModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
          category: ServiceCategory.development,
          oauthType: AuthKind.oauth2,
          authConfig: const {},
          isEnabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final gmail = ServiceProviderModel(
          id: 'gmail',
          name: 'gmail',
          displayName: 'Gmail',
          category: ServiceCategory.communication,
          oauthType: AuthKind.oauth2,
          authConfig: const {},
          isEnabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(github.id, 'github');
        expect(gmail.id, 'gmail');
        expect(github.category, ServiceCategory.development);
        expect(gmail.category, ServiceCategory.communication);
      });
    });
  });
}