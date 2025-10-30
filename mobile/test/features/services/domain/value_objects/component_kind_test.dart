import 'package:flutter_test/flutter_test.dart';
import 'package:area/features/services/domain/value_objects/component_kind.dart';

void main() {
  group('ComponentKind', () {
    group('Enum values', () {
      test('has all required values', () {
        expect(ComponentKind.values.length, 2);
        expect(ComponentKind.values, contains(ComponentKind.action));
        expect(ComponentKind.values, contains(ComponentKind.reaction));
      });

      test('values have correct string representation', () {
        expect(ComponentKind.action.value, 'action');
        expect(ComponentKind.reaction.value, 'reaction');
      });
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(ComponentKind.fromString('action'), ComponentKind.action);
        expect(ComponentKind.fromString('reaction'), ComponentKind.reaction);
      });

      test('defaults to action for unknown strings', () {
        expect(ComponentKind.fromString('unknown'), ComponentKind.action);
        expect(ComponentKind.fromString('trigger'), ComponentKind.action);
        expect(ComponentKind.fromString(''), ComponentKind.action);
      });

      test('is case-sensitive', () {
        expect(ComponentKind.fromString('Action'), ComponentKind.action);
        expect(ComponentKind.fromString('REACTION'), ComponentKind.action);
        expect(
          ComponentKind.fromString('action'.toUpperCase()),
          ComponentKind.action,
        );
      });

      test('handles whitespace', () {
        expect(ComponentKind.fromString(' action'), ComponentKind.action);
        expect(ComponentKind.fromString('action '), ComponentKind.action);
        expect(ComponentKind.fromString(' action '), ComponentKind.action);
      });
    });

    group('displayName getter', () {
      test('returns correct display names', () {
        expect(ComponentKind.action.displayName, 'Action');
        expect(ComponentKind.reaction.displayName, 'Reaction');
      });

      test('display names are user-friendly', () {
        expect(ComponentKind.action.displayName, 'Action');
        expect(ComponentKind.reaction.displayName, 'Reaction');
      });

      test('multiple calls return same display name', () {
        expect(
          ComponentKind.action.displayName,
          ComponentKind.action.displayName,
        );
      });
    });

    group('Round-trip conversion', () {
      test('string to enum and back preserves value', () {
        for (final kind in ComponentKind.values) {
          final converted = ComponentKind.fromString(kind.value);
          expect(converted, kind);
          expect(converted.value, kind.value);
        }
      });
    });

    group('Comparison and equality', () {
      test('enum values are comparable', () {
        expect(ComponentKind.action == ComponentKind.action, true);
        expect(ComponentKind.action == ComponentKind.reaction, false);
      });

      test('can be used in switch statements', () {
        String describe(ComponentKind kind) {
          return switch (kind) {
            ComponentKind.action => 'Trigger when this happens',
            ComponentKind.reaction => 'Then do this',
          };
        }

        expect(
          describe(ComponentKind.action),
          'Trigger when this happens',
        );
        expect(describe(ComponentKind.reaction), 'Then do this');
      });

      test('can be used in if conditions', () {
        final kind = ComponentKind.action;

        if (kind == ComponentKind.action) {
          expect(true, true);
        } else {
          fail('Should have matched action');
        }
      });
    });

    group('Filtering and grouping', () {
      test('can filter components by kind', () {
        const components = [
          ComponentKind.action,
          ComponentKind.reaction,
          ComponentKind.action,
          ComponentKind.reaction,
        ];

        final actions =
            components.where((c) => c == ComponentKind.action).toList();
        expect(actions.length, 2);

        final reactions =
            components.where((c) => c == ComponentKind.reaction).toList();
        expect(reactions.length, 2);
      });

      test('can count by kind', () {
        const components = [
          ComponentKind.action,
          ComponentKind.reaction,
          ComponentKind.action,
        ];

        final actionCount =
            components.where((c) => c == ComponentKind.action).length;
        final reactionCount =
            components.where((c) => c == ComponentKind.reaction).length;

        expect(actionCount, 2);
        expect(reactionCount, 1);
      });
    });

    group('Practical usage', () {
      test('can check if component is action', () {
        bool isAction(ComponentKind kind) => kind == ComponentKind.action;

        expect(isAction(ComponentKind.action), true);
        expect(isAction(ComponentKind.reaction), false);
      });

      test('can check if component is reaction', () {
        bool isReaction(ComponentKind kind) => kind == ComponentKind.reaction;

        expect(isReaction(ComponentKind.action), false);
        expect(isReaction(ComponentKind.reaction), true);
      });

      test('can create component configuration based on kind', () {
        Map<String, dynamic> getConfig(ComponentKind kind) {
          return switch (kind) {
            ComponentKind.action => {
                'label': 'When',
                'color': 'blue',
                'icon': 'trigger',
              },
            ComponentKind.reaction => {
                'label': 'Then',
                'color': 'green',
                'icon': 'action',
              },
          };
        }

        expect(getConfig(ComponentKind.action)['label'], 'When');
        expect(getConfig(ComponentKind.reaction)['label'], 'Then');
      });
    });

    group('Edge cases', () {
      test('repeated conversions are idempotent', () {
        const value = 'action';
        final result1 = ComponentKind.fromString(value);
        final result2 = ComponentKind.fromString(value);
        final result3 = ComponentKind.fromString(value);

        expect(result1, result2);
        expect(result2, result3);
      });

      test('handles each enum value as string correctly', () {
        for (final kind in ComponentKind.values) {
          final restored = ComponentKind.fromString(kind.value);
          expect(restored, kind);
        }
      });
    });

    group('Value consistency', () {
      test('each kind has unique value', () {
        final values = ComponentKind.values.map((k) => k.value).toList();
        final uniqueValues = values.toSet();

        expect(values.length, uniqueValues.length);
      });

      test('each kind has unique display name', () {
        final displayNames =
            ComponentKind.values.map((k) => k.displayName).toList();
        final uniqueNames = displayNames.toSet();

        expect(displayNames.length, uniqueNames.length);
      });
    });
  });
}