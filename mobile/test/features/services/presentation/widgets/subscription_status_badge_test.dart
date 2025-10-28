import 'package:area/features/services/domain/value_objects/subscription_status.dart';
import 'package:area/features/services/presentation/widgets/subscription_status_badge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  group('SubscriptionStatusBadge', () {
    testWidgets('renders available state when not subscribed', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const SubscriptionStatusBadge(
          isSubscribed: false,
        ),
      );

      await tester.pump();

      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('shows active state when subscription is active', (tester) async {
      final subscription = buildSubscription(status: SubscriptionStatus.active);

      await pumpLocalizedWidget(
        tester,
        SubscriptionStatusBadge(
          isSubscribed: true,
          subscription: subscription,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows action required for consent status', (tester) async {
      final subscription = buildSubscription(
        status: SubscriptionStatus.needsConsent,
        identityId: null,
      );

      await pumpLocalizedWidget(
        tester,
        SubscriptionStatusBadge(
          isSubscribed: true,
          subscription: subscription,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Action Required'), findsOneWidget);
    });
  });
}
