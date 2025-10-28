import 'package:area/features/services/presentation/widgets/staggered_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  group('StaggeredAnimation', () {
    testWidgets('animates child to full visibility', (tester) async {
      await pumpLocalizedWidget(
        tester,
        StaggeredAnimation(
          delay: 0,
          child: const Text('Animate me'),
        ),
        withScaffold: false,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);
      expect(find.byType(ScaleTransition), findsOneWidget);
    });
  });

  group('FadeInAnimation', () {
    testWidgets('fades child in immediately', (tester) async {
      await pumpLocalizedWidget(
        tester,
        FadeInAnimation(
          child: const Text('Hello'),
        ),
        withScaffold: false,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(FadeTransition), findsOneWidget);
    });
  });
}
