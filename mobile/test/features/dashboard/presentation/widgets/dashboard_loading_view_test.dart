import 'package:area/features/dashboard/presentation/widgets/dashboard_loading_view.dart';
import 'package:area/features/services/presentation/widgets/animated_loading.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('DashboardLoadingView renders placeholder cards', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const DashboardLoadingView(),
    );

    expect(find.byType(ProfessionalShimmer), findsWidgets);
  });
}
