import 'package:area/features/services/presentation/widgets/service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  group('ServiceCard', () {
    testWidgets('renders service information', (tester) async {
      final service = buildServiceWithStatus();
      await pumpLocalizedWidget(
        tester,
        Center(
          child: SizedBox(
            width: 220,
            child: ServiceCard(
              service: service,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(service.provider.displayName), findsOneWidget);
      expect(
        find.text(service.provider.category.displayName),
        findsOneWidget,
      );
      expect(find.text('S'), findsWidgets);
    });

    testWidgets('invokes callback on tap', (tester) async {
      final service = buildServiceWithStatus();
      var tapped = false;

      await pumpLocalizedWidget(
        tester,
        Center(
          child: SizedBox(
            width: 220,
            child: ServiceCard(
              service: service,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
