import 'package:area/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  group('DashboardCard', () {
    testWidgets('wraps content with InkWell when onTap provided', (tester) async {
      var tapped = false;

      await pumpLocalizedWidget(
        tester,
        DashboardCard(
          onTap: () => tapped = true,
          child: const Text('Content'),
        ),
      );

      await tester.tap(find.text('Content'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders plain card when onTap is null', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const DashboardCard(
          child: Text('Static content'),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Static content'), findsOneWidget);
    });
  });
}
