import 'package:area/features/profile/presentation/widgets/subscribed_services_list.dart';
import 'package:area/features/services/domain/entities/service_with_status.dart';
import 'package:area/features/services/domain/value_objects/service_category.dart';
import 'package:area/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_data.dart';

void main() {
  final binding =
      TestWidgetsFlutterBinding.ensureInitialized()
          as TestWidgetsFlutterBinding;

  setUp(() {
    binding.window.physicalSizeTestValue = const Size(1200, 2000);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('renders empty state and navigates to catalog', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SubscribedServicesList(subscribedServices: const []),
          ),
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('No subscribed services yet.'), findsOneWidget);
    expect(find.text('Discover services'), findsOneWidget);

    await tester.tap(find.text('Discover services'));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/services',
    );
  });

  testWidgets('shows subscribed services list and opens service details', (
    tester,
  ) async {
    final services = <ServiceWithStatus>[
      buildServiceWithStatus(
        provider: buildServiceProvider(
          id: 'calendar',
          displayName: 'Calendar',
          category: ServiceCategory.productivity,
        ),
        isSubscribed: true,
      ),
      buildServiceWithStatus(
        provider: buildServiceProvider(
          id: 'chat',
          displayName: 'Chat',
          category: ServiceCategory.communication,
        ),
        isSubscribed: true,
      ),
    ];

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SubscribedServicesList(subscribedServices: services),
          ),
        ),
        GoRoute(
          path: '/services/:id',
          builder: (context, state) =>
              Text('Details ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Your subscriptions'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/services/calendar',
    );
  });
}
