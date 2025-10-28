import 'package:area/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:area/features/dashboard/presentation/widgets/services_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  testWidgets('ServicesSummaryCard displays metrics and responds to tap', (tester) async {
    final summary = buildServicesSummary(
      connected: 4,
      expiringSoon: 1,
      totalAvailable: 12,
    );
    var tapped = false;

    await pumpLocalizedWidget(
      tester,
      ServicesSummaryCard(
        summary: summary,
        onTap: () => tapped = true,
      ),
    );

    expect(find.text('Services summary'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.byType(DashboardCard));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
