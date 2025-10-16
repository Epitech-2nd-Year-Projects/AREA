import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:area/core/navigation/app_navigation.dart';
import 'package:area/core/navigation/main_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppNavigation', () {
    testWidgets('goTo should navigate using AppNavigation.navigatorKey', (tester) async {
      final router = GoRouter(
        navigatorKey: AppNavigation.navigatorKey,
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/test',
            builder: (_, __) => const Scaffold(body: Text('TestScreen')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      AppNavigation.goTo('/test');
      await tester.pumpAndSettle();

      expect(find.text('TestScreen'), findsOneWidget);
    });

    testWidgets('goBack should navigate back safely', (tester) async {
      // ⚙️ ici, on crée une sous-route imbriquée pour avoir un vrai "pop"
      final router = GoRouter(
        navigatorKey: AppNavigation.navigatorKey,
        initialLocation: '/parent/child',
        routes: [
          GoRoute(
            path: '/parent',
            builder: (_, __) => const Scaffold(body: Text('ParentScreen')),
            routes: [
              GoRoute(
                path: 'child',
                builder: (_, __) => const Scaffold(body: Text('ChildScreen')),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('ChildScreen'), findsOneWidget);

      // Revenir en arrière (retour au parent)
      AppNavigation.goBack();
      await tester.pumpAndSettle();

      expect(find.text('ParentScreen'), findsOneWidget);
    });

    testWidgets('canGoBack returns false when no back stack', (tester) async {
      final router = GoRouter(
        navigatorKey: AppNavigation.navigatorKey,
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Scaffold()),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(AppNavigation.canGoBack(), isFalse);
    });
  });

  group('NavigationShell', () {
    testWidgets('renders its child inside MainScaffold safely', (tester) async {
      final router = GoRouter(
        navigatorKey: AppNavigation.navigatorKey,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
            const NavigationShell(child: Text('ChildContent')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.byType(MainScaffold), findsOneWidget);
      expect(find.text('ChildContent'), findsOneWidget);
    });
  });
}