import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/navigation/navigation_items.dart';
import 'package:area/core/navigation/navigation_destinations.dart';

void main() {
  group('AppNavigationItems', () {
    test('destinations constants should be correct', () {
      expect(AppNavigationItems.destinations.length, 4);
      expect(AppNavigationItems.destinations[0].path, '/dashboard');
    });

    test('getDestinationFromPath exact match', () {
      final result = AppNavigationItems.getDestinationFromPath('/dashboard');
      expect(result, isNotNull);
      expect(result!.destination, AppDestination.dashboard);
    });

    test('getDestinationFromPath partial match', () {
      final result =
      AppNavigationItems.getDestinationFromPath('/services/extra');
      expect(result, isNotNull);
      expect(result!.destination, AppDestination.services);
    });

    test('getDestinationFromPath returns null if no match', () {
      final result = AppNavigationItems.getDestinationFromPath('/unknown');
      expect(result, isNull);
    });

    test('getIndexFromPath returns correct index', () {
      final index = AppNavigationItems.getIndexFromPath('/areas');
      expect(index, 2);
    });

    test('getIndexFromPath returns 0 for unknown path', () {
      final index = AppNavigationItems.getIndexFromPath('/xyz');
      expect(index, 0);
    });

    test('NavigationItem properties', () {
      const item = NavigationItem(
        destination: AppDestination.dashboard,
        label: 'Dash',
        icon: Icons.ac_unit,
        selectedIcon: Icons.abc,
        path: '/x',
      );
      expect(item.label, 'Dash');
      expect(item.icon, Icons.ac_unit);
    });
  });
}