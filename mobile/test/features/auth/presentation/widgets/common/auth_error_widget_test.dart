import 'package:area/features/auth/presentation/widgets/common/auth_error_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  testWidgets('AuthErrorWidget shows retry button when callback provided', (tester) async {
    var retried = false;

    await pumpLocalizedWidget(
      tester,
      AuthErrorWidget(
        title: 'Something went wrong',
        message: 'We could not complete your request.',
        onRetry: () => retried = true,
        retryText: 'Retry now',
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry now'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
