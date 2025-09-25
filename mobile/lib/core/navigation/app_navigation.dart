import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main_scaffold.dart';

class AppNavigation {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void goTo(String path) {
    navigatorKey.currentContext?.go(path);
  }

  static void goBack() {
    navigatorKey.currentContext?.pop();
  }

  static bool canGoBack() {
    return navigatorKey.currentContext?.canPop() ?? false;
  }
}

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MainScaffold(child: child);
  }
}