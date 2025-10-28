import 'package:area/features/services/presentation/widgets/empty_services_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  group('EmptyServicesState', () {
    testWidgets('renders filter state and triggers clear action', (tester) async {
      var cleared = false;

      await pumpLocalizedWidget(
        tester,
        EmptyServicesState(
          hasFilters: true,
          onClearFilters: () => cleared = true,
        ),
      );

      expect(find.text('No services found'), findsOneWidget);

      await tester.tap(find.text('Clear Filters'));
      await tester.pump();

      expect(cleared, isTrue);
    });

    testWidgets('renders empty state without filters', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const EmptyServicesState(hasFilters: false),
      );

      expect(find.text('No services available.'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Clear Filters'),
        findsNothing,
      );
    });
  });
}
