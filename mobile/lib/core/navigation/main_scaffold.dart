import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation_items.dart';
import 'widgets/app_bottom_navigation_bar.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedIndex = AppNavigationItems.getIndexFromPath(currentLocation);

    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                final destination = AppNavigationItems.destinations[index];
                context.go(destination.path);
              },
            ),
          ),
        ],
      ),
    );
  }
}
