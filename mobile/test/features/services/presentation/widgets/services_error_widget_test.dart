import 'package:area/features/services/presentation/widgets/services_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('ServicesErrorWidget displays message and invokes retry', (tester) async {
    var retried = false;

    await pumpLocalizedWidget(
      tester,
      ServicesErrorWidget(
        title: 'Failed to load',
        message: 'Something went wrong',
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
