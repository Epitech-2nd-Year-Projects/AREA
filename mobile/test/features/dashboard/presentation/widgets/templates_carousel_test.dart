import 'package:area/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:area/features/dashboard/presentation/widgets/templates_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;

  setUp(() {
    binding.window.physicalSizeTestValue = const Size(1200, 2000);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('TemplatesCarousel renders cards and handles selection', (tester) async {
    final template = buildDashboardTemplate(
      title: 'Sync calendar tasks',
      description: 'Sync tasks',
      primaryService: 'Calendar',
      secondaryService: 'Tasks',
    );
    DashboardTemplate? selected;

    await pumpLocalizedWidget(
      tester,
      MediaQuery(
        data: const MediaQueryData(size: Size(1200, 2000), textScaleFactor: 0.8),
        child: SingleChildScrollView(
          child: SizedBox(
            width: 800,
            height: 600,
            child: TemplatesCarousel(
              templates: [template],
              onUseTemplate: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recommended templates'), findsOneWidget);
    expect(find.text(template.title), findsOneWidget);
    expect(find.text('Use template'), findsOneWidget);

    await tester.tap(find.text('Use template'));
    await tester.pump();

    expect(selected, template);
  });

  testWidgets('TemplatesCarousel renders nothing when list empty', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const MediaQuery(
        data: MediaQueryData(size: Size(1200, 2000), textScaleFactor: 0.8),
        child: SingleChildScrollView(
          child: SizedBox(
            width: 800,
            height: 600,
            child: TemplatesCarousel(
              templates: [],
              onUseTemplate: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recommended templates'), findsNothing);
  });
}

void _noop(DashboardTemplate _) {}
