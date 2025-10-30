import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/areas/domain/entities/area.dart';
import 'package:area/features/areas/domain/entities/area_component_binding.dart';
import 'package:area/features/areas/domain/entities/area_status.dart';
import 'package:area/features/services/domain/entities/service_component.dart';
import 'package:area/features/services/domain/value_objects/component_kind.dart';
import 'package:area/features/services/domain/entities/service_provider_summary.dart';

void main() {
  group('Area', () {
    late DateTime createdAt;
    late DateTime updatedAt;
    late ServiceComponent testComponent;
    late AreaComponentBinding testAction;
    late AreaComponentBinding testReaction;

    setUp(() {
      createdAt = DateTime(2024, 1, 1, 10, 0);
      updatedAt = DateTime(2024, 1, 2, 15, 0);

      testComponent = ServiceComponent(
        id: 'component-1',
        kind: ComponentKind.action,
        name: 'new_email',
        displayName: 'New Email',
        description: 'When a new email arrives',
        provider: const ServiceProviderSummary(
          id: 'gmail',
          name: 'gmail',
          displayName: 'Gmail',
        ),
        metadata: const {},
        parameters: const [],
      );

      testAction = AreaComponentBinding(
        configId: 'config-1',
        componentId: 'component-1',
        name: 'New Email',
        params: const {'label': 'Inbox'},
        component: testComponent,
      );

      testReaction = AreaComponentBinding(
        configId: 'config-2',
        componentId: 'component-2',
        name: 'Send Notification',
        params: const {'title': 'New Email'},
        component: testComponent,
      );
    });

    group('Constructor', () {
      test('creates instance with all parameters', () {
        final area = Area(
          id: 'area-1',
          name: 'Email Notification',
          description: 'Get notified when new email arrives',
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area.id, 'area-1');
        expect(area.name, 'Email Notification');
        expect(area.description, 'Get notified when new email arrives');
        expect(area.status, AreaStatus.enabled);
        expect(area.createdAt, createdAt);
        expect(area.updatedAt, updatedAt);
        expect(area.action, testAction);
        expect(area.reactions.length, 1);
      });

      test('creates instance with null description', () {
        final area = Area(
          id: 'area-1',
          name: 'Simple Area',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area.description, isNull);
      });

      test('creates instance with multiple reactions', () {
        final reaction2 = AreaComponentBinding(
          configId: 'config-3',
          componentId: 'component-3',
          name: 'Save to Database',
          params: const {},
          component: testComponent,
        );

        final area = Area(
          id: 'area-1',
          name: 'Multi Reaction Area',
          description: 'Test multiple reactions',
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction, reaction2],
        );

        expect(area.reactions.length, 2);
        expect(area.reactions[0].name, 'Send Notification');
        expect(area.reactions[1].name, 'Save to Database');
      });
    });

    group('isEnabled getter', () {
      test('returns true when status is enabled', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area.isEnabled, true);
      });

      test('returns false when status is disabled', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.disabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area.isEnabled, false);
      });

      test('returns false when status is archived', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.archived,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area.isEnabled, false);
      });

      test('reflects status changes through copyWith', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area.isEnabled, true);

        final disabled = area.copyWith(status: AreaStatus.disabled);
        expect(disabled.isEnabled, false);
      });
    });

    group('copyWith', () {
      test('creates copy with same values when no arguments provided', () {
        final area = Area(
          id: 'area-1',
          name: 'Original',
          description: 'Original description',
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final copy = area.copyWith();

        expect(copy.id, area.id);
        expect(copy.name, area.name);
        expect(copy.description, area.description);
        expect(copy.status, area.status);
      });

      test('creates copy with updated id', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(id: 'area-2');

        expect(updated.id, 'area-2');
        expect(updated.name, area.name);
      });

      test('creates copy with updated name', () {
        final area = Area(
          id: 'area-1',
          name: 'Original Name',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(name: 'Updated Name');

        expect(updated.name, 'Updated Name');
        expect(updated.id, area.id);
      });

      test('creates copy with updated description', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: 'Old description',
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(description: 'New description');

        expect(updated.description, 'New description');
      });

      test('creates copy with updated status', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(status: AreaStatus.disabled);

        expect(updated.status, AreaStatus.disabled);
        expect(updated.isEnabled, false);
      });

      test('creates copy with updated timestamps', () {
        final newCreatedAt = DateTime(2024, 2, 1);
        final newUpdatedAt = DateTime(2024, 2, 2);

        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
        );

        expect(updated.createdAt, newCreatedAt);
        expect(updated.updatedAt, newUpdatedAt);
      });

      test('creates copy with updated action', () {
        final newAction = AreaComponentBinding(
          configId: 'new-config',
          componentId: 'new-component',
          name: 'New Action',
          params: const {},
          component: testComponent,
        );

        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(action: newAction);

        expect(updated.action.name, 'New Action');
        expect(updated.action.configId, 'new-config');
      });

      test('creates copy with updated reactions', () {
        final newReaction = AreaComponentBinding(
          configId: 'new-reaction-config',
          componentId: 'new-reaction-component',
          name: 'New Reaction',
          params: const {},
          component: testComponent,
        );

        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(reactions: [newReaction]);

        expect(updated.reactions.length, 1);
        expect(updated.reactions[0].name, 'New Reaction');
      });

      test('creates copy with multiple updates', () {
        final newUpdatedAt = DateTime(2024, 3, 1);
        final newReaction = AreaComponentBinding(
          configId: 'new-config',
          componentId: 'new-component',
          name: 'Updated',
          params: const {},
          component: testComponent,
        );

        final area = Area(
          id: 'area-1',
          name: 'Original',
          description: 'Original description',
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final updated = area.copyWith(
          name: 'Updated',
          description: 'Updated description',
          status: AreaStatus.disabled,
          updatedAt: newUpdatedAt,
          reactions: [newReaction],
        );

        expect(updated.name, 'Updated');
        expect(updated.description, 'Updated description');
        expect(updated.status, AreaStatus.disabled);
        expect(updated.updatedAt, newUpdatedAt);
        expect(updated.reactions[0].name, 'Updated');
        expect(updated.id, area.id);
        expect(updated.createdAt, area.createdAt);
      });

      test('does not modify original area', () {
        final area = Area(
          id: 'area-1',
          name: 'Original',
          description: 'Original description',
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final originalName = area.name;
        final originalStatus = area.status;

        area.copyWith(name: 'Modified', status: AreaStatus.disabled);

        expect(area.name, originalName);
        expect(area.status, originalStatus);
      });
    });

    group('Equality', () {
      test('areas with same values are equal', () {
        final area1 = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final area2 = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area1, area2);
      });

      test('areas with different ids are not equal', () {
        final area1 = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final area2 = Area(
          id: 'area-2',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area1, isNot(area2));
      });

      test('areas with different status are not equal', () {
        final area1 = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final area2 = Area(
          id: 'area-1',
          name: 'Test',
          description: null,
          status: AreaStatus.disabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area1, isNot(area2));
      });
    });

    group('Props for Equatable', () {
      test('includes all important fields in props', () {
        final area = Area(
          id: 'area-1',
          name: 'Test',
          description: 'Description',
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        final props = area.props;

        expect(props.length, 8);
        expect(props.contains('area-1'), true);
        expect(props.contains('Test'), true);
        expect(props.contains(AreaStatus.enabled), true);
      });
    });

    group('Practical scenarios', () {
      test('enables an area', () {
        var area = Area(
          id: 'area-1',
          name: 'Email Digest',
          description: null,
          status: AreaStatus.disabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        expect(area.isEnabled, false);

        area = area.copyWith(
          status: AreaStatus.enabled,
          updatedAt: DateTime.now(),
        );

        expect(area.isEnabled, true);
      });

      test('archives an area', () {
        var area = Area(
          id: 'area-1',
          name: 'Old Area',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        area = area.copyWith(status: AreaStatus.archived);

        expect(area.status, AreaStatus.archived);
        expect(area.isEnabled, false);
      });

      test('updates area with new reactions', () {
        final newReaction1 = AreaComponentBinding(
          configId: 'config-3',
          componentId: 'component-3',
          name: 'Save to Drive',
          params: const {},
          component: testComponent,
        );

        final newReaction2 = AreaComponentBinding(
          configId: 'config-4',
          componentId: 'component-4',
          name: 'Send Email',
          params: const {},
          component: testComponent,
        );

        var area = Area(
          id: 'area-1',
          name: 'Enhanced Area',
          description: null,
          status: AreaStatus.enabled,
          createdAt: createdAt,
          updatedAt: updatedAt,
          action: testAction,
          reactions: [testReaction],
        );

        area = area.copyWith(reactions: [newReaction1, newReaction2]);

        expect(area.reactions.length, 2);
        expect(area.reactions[0].name, 'Save to Drive');
        expect(area.reactions[1].name, 'Send Email');
      });
    });
  });
}