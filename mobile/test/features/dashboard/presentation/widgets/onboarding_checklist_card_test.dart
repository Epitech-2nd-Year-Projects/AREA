import 'package:area/features/dashboard/presentation/widgets/onboarding_checklist_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  testWidgets('OnboardingChecklistCard renders steps with localized titles', (tester) async {
    final checklist = buildChecklist();

    await pumpLocalizedWidget(
      tester,
      OnboardingChecklistCard(checklist: checklist),
    );

    expect(find.text('Onboarding checklist'), findsOneWidget);
    expect(find.text('Connect a service'), findsOneWidget);
    expect(find.text('Create an Area'), findsOneWidget);
  });
}
