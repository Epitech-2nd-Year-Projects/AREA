import 'package:area/features/auth/presentation/widgets/buttons/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  group('AuthButton', () {
    testWidgets('fires onPressed when enabled', (tester) async {
      var tapped = false;

      await pumpLocalizedWidget(
        tester,
        AuthButton(
          text: 'Continue',
          onPressed: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator and disables tap', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const AuthButton(
          text: 'Sign in',
          variant: AuthButtonVariant.outline,
          isLoading: true,
        ),
      );

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
