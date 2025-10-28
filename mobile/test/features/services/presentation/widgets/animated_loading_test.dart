import 'package:area/features/services/presentation/widgets/animated_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  group('Animated loading widgets', () {
    testWidgets('ProfessionalShimmer wraps child with shader mask', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const ProfessionalShimmer(
          child: Text('Loading...'),
        ),
        withScaffold: false,
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('ServiceCardSkeleton renders expected placeholders in dark mode', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const ServiceCardSkeleton(),
        themeMode: ThemeMode.dark,
      );

      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });
  });
}
