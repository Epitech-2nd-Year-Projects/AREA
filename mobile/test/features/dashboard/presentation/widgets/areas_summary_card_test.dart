import 'package:area/features/dashboard/presentation/widgets/areas_summary_card.dart';
import 'package:area/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  testWidgets('AreasSummaryCard shows counts and handles taps', (tester) async {
    final summary = buildAreasSummary(
      active: 6,
      paused: 2,
      failuresLast24h: 1,
    );
    var tapped = false;

    await pumpLocalizedWidget(
      tester,
      AreasSummaryCard(
        summary: summary,
        onTap: () => tapped = true,
      ),
    );

    expect(find.text('Areas summary'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.byType(DashboardCard));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
