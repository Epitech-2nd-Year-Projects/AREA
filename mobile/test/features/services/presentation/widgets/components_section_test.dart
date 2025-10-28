import 'package:area/features/services/domain/value_objects/component_kind.dart';
import 'package:area/features/services/presentation/widgets/components_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;

  setUp(() {
    binding.window.physicalSizeTestValue = const Size(1200, 2000);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  group('ComponentsSection', () {
    testWidgets('shows counts per tab and allows switching between tabs', (tester) async {
      final components = [
        buildServiceComponent(
          id: 'action-1',
          displayName: 'Create calendar event',
          kind: ComponentKind.action,
        ),
        buildServiceComponent(
          id: 'action-2',
          displayName: 'Send email',
          kind: ComponentKind.action,
        ),
        buildServiceComponent(
          id: 'reaction-1',
          displayName: 'Create task',
          kind: ComponentKind.reaction,
        ),
      ];

      final searchQueries = <String>[];

      await pumpLocalizedWidget(
        tester,
        SingleChildScrollView(
          child: SizedBox(
            height: 720,
            child: ComponentsSection(
              components: components,
              selectedKind: null,
              searchQuery: 'create',
              onFilterChanged: (_) {},
              onSearchChanged: searchQueries.add,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Available Components'), findsOneWidget);
      expect(find.text('Actions (2)'), findsOneWidget);
      expect(find.text('Reactions (1)'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();
      expect(searchQueries.last, isEmpty);

      await tester.tap(find.text('Reactions (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Create task'), findsOneWidget);
      expect(find.text('Create calendar event'), findsNothing);

      await tester.tap(find.text('Actions (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Send email'), findsOneWidget);
    });
  });
}
