import 'package:area/features/services/presentation/widgets/services_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  group('ServicesSearchBar', () {
    testWidgets('calls onSearch as text changes', (tester) async {
      final queries = <String>[];

      await pumpLocalizedWidget(
        tester,
        SizedBox(
          width: 360,
          child: ServicesSearchBar(
            onSearch: queries.add,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'calendar');
      await tester.pump();

      expect(queries, contains('calendar'));
    });

    testWidgets('clear icon resets search and invokes callback', (tester) async {
      final queries = <String>[];

      await pumpLocalizedWidget(
        tester,
        SizedBox(
          width: 360,
          child: ServicesSearchBar(
            onSearch: queries.add,
            initialValue: 'slack',
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(queries.last, isEmpty);
    });

    testWidgets('shows clear filters action when filters active', (tester) async {
      var cleared = false;

      await pumpLocalizedWidget(
        tester,
        SizedBox(
          width: 360,
          child: ServicesSearchBar(
            onSearch: (_) {},
            hasActiveFilters: true,
            onClear: () => cleared = true,
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(cleared, isTrue);
    });
  });
}
