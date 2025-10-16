import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:area/core/navigation/main_scaffold.dart';
import 'package:area/core/navigation/navigation_items.dart';
import 'package:area/core/navigation/widgets/app_bottom_navigation_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MainScaffold shows bottomNavigation and responds to taps',
          (tester) async {
        final router = GoRouter(
          initialLocation: '/dashboard',
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const MainScaffold(
                child: Text('DashboardScreen'),
              ),
            ),
            GoRoute(
              path: '/services',
              builder: (context, state) => const MainScaffold(
                child: Text('ServicesScreen'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.byType(MainScaffold), findsOneWidget);
        expect(find.byType(AppBottomNavigationBar), findsOneWidget);
        expect(find.text('DashboardScreen'), findsOneWidget);

        final bottomBar =
        tester.widget<AppBottomNavigationBar>(find.byType(AppBottomNavigationBar));

        bottomBar.onDestinationSelected(1);
        await tester.pumpAndSettle();

        expect(find.text('ServicesScreen'), findsOneWidget);

        final dest = AppNavigationItems.destinations[1];
        expect(dest.label, equals('Services'));
      });
}