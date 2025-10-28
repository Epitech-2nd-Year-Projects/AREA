import 'package:area/features/auth/presentation/widgets/common/auth_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  group('AuthLoadingWidget', () {
    testWidgets('displays loader with message', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const AuthLoadingWidget(message: 'Signing you in...'),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Signing you in...'), findsOneWidget);
    });

    testWidgets('can hide logo decoration', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const AuthLoadingWidget(
          showLogo: false,
          message: 'Loading',
        ),
      );

      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });
  });
}
