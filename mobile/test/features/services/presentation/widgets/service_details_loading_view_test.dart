import 'package:area/features/services/presentation/widgets/animated_loading.dart';
import 'package:area/features/services/presentation/widgets/service_details_loading.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('ServiceDetailsLoadingView shows skeleton sections', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const ServiceDetailsLoadingView(),
      withScaffold: false,
    );

    expect(find.byType(ServiceDetailsSkeletonSection), findsNWidgets(2));
  });
}
