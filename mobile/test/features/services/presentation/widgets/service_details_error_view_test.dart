import 'package:area/features/services/presentation/widgets/service_details_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('ServiceDetailsErrorView renders error and handles retry', (tester) async {
    var retried = false;

    await pumpLocalizedWidget(
      tester,
      ServiceDetailsErrorView(
        title: 'Service unavailable',
        message: 'We could not load that service.',
        onRetry: () => retried = true,
      ),
      withScaffold: false,
    );

    expect(find.text('Service unavailable'), findsOneWidget);
    expect(find.text('We could not load that service.'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pump();

    expect(retried, isTrue);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
