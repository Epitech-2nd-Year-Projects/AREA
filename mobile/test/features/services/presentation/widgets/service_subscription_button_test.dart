import 'package:area/features/services/domain/entities/user_service_subscription.dart';
import 'package:area/features/services/domain/value_objects/subscription_status.dart';
import 'package:area/features/services/presentation/widgets/service_subscription_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  group('ServiceSubscriptionButton', () {
    testWidgets('shows subscribe label and triggers onSubscribe', (tester) async {
      final provider = buildServiceProvider(displayName: 'Slack');
      var subscribed = false;

      await pumpLocalizedWidget(
        tester,
        ServiceSubscriptionButton(
          service: provider,
          isLoading: false,
          onSubscribe: () => subscribed = true,
          onUnsubscribe: () {},
        ),
      );

      expect(find.text('Subscribe'), findsOneWidget);

      await tester.tap(find.text('Subscribe'));
      await tester.pump();

      expect(subscribed, isTrue);
    });

    testWidgets('shows unsubscribe state when subscription is active', (tester) async {
      final provider = buildServiceProvider(displayName: 'GitHub');
      final subscription = buildSubscription(
        providerId: provider.id,
        status: SubscriptionStatus.active,
      );
      var unsubscribed = false;

      await pumpLocalizedWidget(
        tester,
        ServiceSubscriptionButton(
          service: provider,
          subscription: subscription,
          isLoading: false,
          onSubscribe: () {},
          onUnsubscribe: () => unsubscribed = true,
        ),
      );

      expect(find.text('Unsubscribe'), findsOneWidget);

      await tester.tap(find.text('Unsubscribe'));
      await tester.pump();

      expect(unsubscribed, isTrue);
    });

    testWidgets('disables button and shows loader while loading', (tester) async {
      final provider = buildServiceProvider();

      await pumpLocalizedWidget(
        tester,
        ServiceSubscriptionButton(
          service: provider,
          isLoading: true,
          onSubscribe: () {},
          onUnsubscribe: () {},
        ),
      );

      final ButtonStyleButton button = tester.widget(
        find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      ) as ButtonStyleButton;
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
