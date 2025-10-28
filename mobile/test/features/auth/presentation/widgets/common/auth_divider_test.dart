import 'package:area/features/auth/presentation/widgets/common/auth_divider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  testWidgets('AuthDivider displays divider text', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const AuthDivider(text: 'or continue with'),
    );

    expect(find.text('or continue with'), findsOneWidget);
  });
}
