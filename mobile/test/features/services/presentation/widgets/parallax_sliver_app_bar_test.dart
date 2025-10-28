import 'package:area/features/services/presentation/widgets/parallax_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('ParallaxSliverAppBar renders title, action and back button', (tester) async {
    var backPressed = false;

    await pumpLocalizedWidget(
      tester,
      CustomScrollView(
        slivers: [
          ParallaxSliverAppBar(
            title: 'Service details',
            onBackPressed: () => backPressed = true,
            actionWidget: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      withScaffold: false,
    );

    await tester.pump();

    expect(find.text('Service details'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    await tester.tap(find.byTooltip('Go back'));
    await tester.pump();

    expect(backPressed, isTrue);
  });
}
