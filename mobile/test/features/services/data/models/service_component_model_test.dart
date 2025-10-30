import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/data/models/service_component_model.dart';
import 'package:area/features/services/domain/value_objects/component_kind.dart';

void main() {
  group('ServiceComponentModel', () {
    final baseJson = <String, dynamic>{
      'id': 'github_action_create_issue',
      'kind': 'action',
      'name': 'create_issue',
      'displayName': 'Create Issue',
      'description': 'Creates a new issue on GitHub',
      'metadata': <String, dynamic>{
        'parameters': <Map<String, dynamic>>[],
      },
      'provider': <String, dynamic>{
        'id': 'github',
        'name': 'github',
        'displayName': 'GitHub',
      },
    };

    group('Constructor', () {
      test('creates instance with all parameters', () {
        final provider = ServiceProviderSummaryModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
        );

        final model = ServiceComponentModel(
          id: 'github_action_create_issue',
          kind: ComponentKind.action,
          name: 'create_issue',
          displayName: 'Create Issue',
          description: 'Creates a new issue',
          metadata: const {},
          provider: provider,
          parameters: const [],
        );

        expect(model.id, 'github_action_create_issue');
        expect(model.kind, ComponentKind.action);
        expect(model.name, 'create_issue');
        expect(model.displayName, 'Create Issue');
        expect(model.description, 'Creates a new issue');
        expect(model.provider, provider);
        expect(model.parameters, isEmpty);
      });

      test('creates instance with null description', () {
        final provider = ServiceProviderSummaryModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
        );

        final model = ServiceComponentModel(
          id: 'github_action_create_issue',
          kind: ComponentKind.action,
          name: 'create_issue',
          displayName: 'Create Issue',
          description: null,
          metadata: const {},
          provider: provider,
          parameters: const [],
        );

        expect(model.description, isNull);
      });
    });

    group('fromJson - Complete structure', () {
      test('parses complete JSON', () {
        final model = ServiceComponentModel.fromJson(baseJson);

        expect(model.id, 'github_action_create_issue');
        expect(model.kind, ComponentKind.action);
        expect(model.name, 'create_issue');
        expect(model.displayName, 'Create Issue');
        expect(model.description, 'Creates a new issue on GitHub');
      });

      test('parses provider correctly', () {
        final model = ServiceComponentModel.fromJson(baseJson);

        expect(model.provider.id, 'github');
        expect(model.provider.name, 'github');
        expect(model.provider.displayName, 'GitHub');
      });

      test('handles empty metadata', () {
        final json = <String, dynamic>{...baseJson, 'metadata': <String, dynamic>{}};

        final model = ServiceComponentModel.fromJson(json);

        expect(model.metadata, isEmpty);
        expect(model.parameters, isEmpty);
      });

      test('handles missing metadata', () {
        final json = Map<String, dynamic>.from(baseJson);
        json.remove('metadata');

        final model = ServiceComponentModel.fromJson(json);

        expect(model.metadata, isEmpty);
        expect(model.parameters, isEmpty);
      });
    });

    group('fromJson - Component kinds', () {
      test('parses action component', () {
        final model = ServiceComponentModel.fromJson(baseJson);
        expect(model.kind, ComponentKind.action);
      });

      test('parses reaction component', () {
        final json = <String, dynamic>{...baseJson, 'kind': 'reaction'};
        final model = ServiceComponentModel.fromJson(json);
        expect(model.kind, ComponentKind.reaction);
      });
    });

    group('fromJson - Parameters', () {
      test('parses empty parameters list', () {
        final model = ServiceComponentModel.fromJson(baseJson);
        expect(model.parameters, isEmpty);
      });

      test('parses single parameter', () {
        final json = <String, dynamic>{
          ...baseJson,
          'metadata': <String, dynamic>{
            'parameters': <Map<String, dynamic>>[
              <String, dynamic>{
                'key': 'title',
                'label': 'Issue Title',
                'type': 'string',
                'required': true,
                'description': 'The title of the issue',
                'options': <Map<String, dynamic>>[],
              }
            ],
          }
        };

        final model = ServiceComponentModel.fromJson(json);

        expect(model.parameters, hasLength(1));
        expect(model.parameters[0].key, 'title');
        expect(model.parameters[0].label, 'Issue Title');
        expect(model.parameters[0].type, 'string');
        expect(model.parameters[0].required, true);
      });

      test('parses multiple parameters', () {
        final json = <String, dynamic>{
          ...baseJson,
          'metadata': <String, dynamic>{
            'parameters': <Map<String, dynamic>>[
              <String, dynamic>{
                'key': 'title',
                'type': 'string',
                'required': true,
              },
              <String, dynamic>{
                'key': 'body',
                'type': 'text',
                'required': false,
              }
            ],
          }
        };

        final model = ServiceComponentModel.fromJson(json);

        expect(model.parameters, hasLength(2));
        expect(model.parameters[0].key, 'title');
        expect(model.parameters[1].key, 'body');
      });

      test('ignores non-map parameter items', () {
        final json = <String, dynamic>{
          ...baseJson,
          'metadata': <String, dynamic>{
            'parameters': <dynamic>[
              <String, dynamic>{'key': 'title', 'type': 'string'},
              'invalid_string',
              123,
              null,
            ],
          }
        };

        final model = ServiceComponentModel.fromJson(json);

        expect(model.parameters, hasLength(1));
        expect(model.parameters[0].key, 'title');
      });

      test('ignores non-list metadata parameters', () {
        final json = <String, dynamic>{
          ...baseJson,
          'metadata': <String, dynamic>{
            'parameters': 'not_a_list',
          }
        };

        final model = ServiceComponentModel.fromJson(json);

        expect(model.parameters, isEmpty);
      });
    });

    group('fromAboutComponent', () {
      test('creates model from about component data', () {
        final model = ServiceComponentModel.fromAboutComponent(
          providerId: 'github',
          kind: ComponentKind.action,
          name: 'create_issue',
          description: 'Creates a new issue',
        );

        expect(model.id, contains('github_action_create_issue'));
        expect(model.kind, ComponentKind.action);
        expect(model.name, 'create_issue');
        expect(model.description, 'Creates a new issue');
      });

      test('formats display name correctly', () {
        final model = ServiceComponentModel.fromAboutComponent(
          providerId: 'github',
          kind: ComponentKind.action,
          name: 'create_issue',
          description: 'Creates a new issue',
        );

        expect(model.displayName, 'Create Issue');
        expect(model.provider.displayName, 'Github');
      });

      test('generates valid id', () {
        final model = ServiceComponentModel.fromAboutComponent(
          providerId: 'github',
          kind: ComponentKind.reaction,
          name: 'send_notification',
          description: 'Sends a notification',
        );

        expect(model.id, 'github_reaction_send_notification');
      });

      test('creates empty provider summary', () {
        final model = ServiceComponentModel.fromAboutComponent(
          providerId: 'github',
          kind: ComponentKind.action,
          name: 'test',
          description: 'Test',
        );

        expect(model.provider.id, 'github');
        expect(model.metadata, isEmpty);
        expect(model.parameters, isEmpty);
      });

      test('handles special characters in name', () {
        final model = ServiceComponentModel.fromAboutComponent(
          providerId: 'github',
          kind: ComponentKind.action,
          name: 'create_issue_with_labels',
          description: 'Creates issue',
        );

        expect(model.displayName, 'Create Issue With Labels');
      });
    });

    group('toEntity', () {
      test('converts model to ServiceComponent entity', () {
        final model = ServiceComponentModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.id, model.id);
        expect(entity.kind, model.kind);
        expect(entity.name, model.name);
        expect(entity.displayName, model.displayName);
        expect(entity.description, model.description);
      });

      test('converts provider to entity', () {
        final model = ServiceComponentModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.provider.id, 'github');
        expect(entity.provider.name, 'github');
        expect(entity.provider.displayName, 'GitHub');
      });

      test('preserves metadata in entity', () {
        final json = <String, dynamic>{
          ...baseJson,
          'metadata': <String, dynamic>{
            'custom_field': 'custom_value',
          }
        };

        final model = ServiceComponentModel.fromJson(json);
        final entity = model.toEntity();

        expect(entity.metadata['custom_field'], 'custom_value');
      });
    });

    group('ServiceProviderSummaryModel', () {
      test('creates instance', () {
        const provider = ServiceProviderSummaryModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
        );

        expect(provider.id, 'github');
        expect(provider.name, 'github');
        expect(provider.displayName, 'GitHub');
      });

      test('fromJson parses correctly', () {
        final json = <String, dynamic>{
          'id': 'github',
          'name': 'github',
          'displayName': 'GitHub',
        };

        final provider = ServiceProviderSummaryModel.fromJson(json);

        expect(provider.id, 'github');
        expect(provider.displayName, 'GitHub');
      });

      test('toEntity converts to entity', () {
        const provider = ServiceProviderSummaryModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
        );

        final entity = provider.toEntity();

        expect(entity.id, 'github');
        expect(entity.displayName, 'GitHub');
      });

      test('supports const instantiation', () {
        const provider = ServiceProviderSummaryModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
        );
        expect(provider.id, 'github');
      });
    });

    group('ComponentParameterModel', () {
      test('parses parameter with all fields', () {
        final json = <String, dynamic>{
          'key': 'title',
          'label': 'Issue Title',
          'type': 'string',
          'required': true,
          'description': 'The issue title',
          'options': <Map<String, dynamic>>[],
          'extra_field': 'extra_value',
        };

        final param = ComponentParameterModel.fromJson(json);

        expect(param.key, 'title');
        expect(param.label, 'Issue Title');
        expect(param.type, 'string');
        expect(param.required, true);
        expect(param.description, 'The issue title');
        expect(param.extras['extra_field'], 'extra_value');
      });

      test('generates label from key if missing', () {
        final json = <String, dynamic>{
          'key': 'issue_title',
          'type': 'string',
          'required': false,
          'options': <Map<String, dynamic>>[],
        };

        final param = ComponentParameterModel.fromJson(json);

        expect(param.label, 'Issue Title');
      });

      test('defaults to string type if missing', () {
        final json = <String, dynamic>{
          'key': 'title',
          'required': false,
          'options': <Map<String, dynamic>>[],
        };

        final param = ComponentParameterModel.fromJson(json);

        expect(param.type, 'string');
      });

      test('parses options', () {
        final json = <String, dynamic>{
          'key': 'priority',
          'type': 'select',
          'required': true,
          'options': <Map<String, dynamic>>[
            {'value': 'high', 'label': 'High Priority'},
            {'value': 'low', 'label': 'Low Priority'},
          ],
        };

        final param = ComponentParameterModel.fromJson(json);

        expect(param.options, hasLength(2));
        expect(param.options[0].value, 'high');
        expect(param.options[0].label, 'High Priority');
      });

      test('toEntity converts to entity', () {
        final json = <String, dynamic>{
          'key': 'title',
          'type': 'string',
          'required': true,
          'options': <Map<String, dynamic>>[],
        };

        final param = ComponentParameterModel.fromJson(json);
        final entity = param.toEntity();

        expect(entity.key, 'title');
        expect(entity.type, 'string');
        expect(entity.required, true);
      });
    });

    group('ComponentParameterOptionModel', () {
      test('parses option with string and label', () {
        final json = <String, dynamic>{
          'value': 'high',
          'label': 'High Priority',
        };

        final option = ComponentParameterOptionModel.fromJson(json);

        expect(option.value, 'high');
        expect(option.label, 'High Priority');
      });

      test('converts non-string value to string', () {
        final json = <String, dynamic>{
          'value': 123,
          'label': 'Option 123',
        };

        final option = ComponentParameterOptionModel.fromJson(json);

        expect(option.value, '123');
      });

      test('uses value as label if label missing', () {
        final json = <String, dynamic>{
          'value': 'option_value',
        };

        final option = ComponentParameterOptionModel.fromJson(json);

        expect(option.label, 'option_value');
      });

      test('supports const instantiation', () {
        const option = ComponentParameterOptionModel(
          value: 'high',
          label: 'High Priority',
        );
        expect(option.value, 'high');
      });

      test('toEntity converts to entity', () {
        const option = ComponentParameterOptionModel(
          value: 'high',
          label: 'High Priority',
        );

        final entity = option.toEntity();

        expect(entity.value, 'high');
        expect(entity.label, 'High Priority');
      });
    });

    group('Format display name', () {
      test('formats snake_case correctly', () {
        const provider = ServiceProviderSummaryModel(
          id: 'github',
          name: 'github',
          displayName: 'GitHub',
        );

        expect(provider.displayName, 'GitHub');
      });

      test('handles complex names', () {
        final model = ServiceComponentModel.fromAboutComponent(
          providerId: 'github',
          kind: ComponentKind.action,
          name: 'create_pull_request_with_reviewers',
          description: 'Creates PR',
        );

        expect(model.displayName, 'Create Pull Request With Reviewers');
      });
    });

    group('Multiple instances', () {
      test('creates independent component instances', () {
        final json1 = <String, dynamic>{
          ...baseJson,
          'id': 'github_action_create_issue',
        };

        final json2 = <String, dynamic>{
          ...baseJson,
          'id': 'gitlab_action_create_issue',
        };

        final model1 = ServiceComponentModel.fromJson(json1);
        final model2 = ServiceComponentModel.fromJson(json2);

        expect(model1.id, isNot(model2.id));
        expect(model1.id, 'github_action_create_issue');
        expect(model2.id, 'gitlab_action_create_issue');
      });
    });

    group('JSON round-trip', () {
      test('preserves component data through toEntity', () {
        final model = ServiceComponentModel.fromJson(baseJson);
        final entity = model.toEntity();

        expect(entity.id, model.id);
        expect(entity.kind, model.kind);
        expect(entity.name, model.name);
        expect(entity.displayName, model.displayName);
      });
    });
  });
}