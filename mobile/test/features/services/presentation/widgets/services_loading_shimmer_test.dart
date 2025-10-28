import 'package:area/features/services/presentation/widgets/animated_loading.dart';
import 'package:area/features/services/presentation/widgets/services_loading_shimmer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('ServicesLoadingShimmer renders skeleton grid', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const ServicesLoadingShimmer(),
    );

    await tester.pump();

    expect(find.byType(ServiceCardSkeleton), findsNWidgets(6));
  });
}
