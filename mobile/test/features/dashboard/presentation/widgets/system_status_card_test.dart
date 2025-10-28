import 'package:area/features/dashboard/presentation/widgets/system_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  testWidgets('SystemStatusCard reflects offline state and retry action', (tester) async {
    final status = buildSystemStatus(
      isReachable: false,
      lastPingMs: 180,
      lastSyncedAt: DateTime(2024, 1, 1, 9, 30),
      message: 'API temporarily unavailable',
    );
    var retried = false;

    await pumpLocalizedWidget(
      tester,
      SystemStatusCard(
        status: status,
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('System status'), findsOneWidget);
    expect(find.text('API temporarily unavailable'), findsOneWidget);
    expect(find.text('180 ms'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
