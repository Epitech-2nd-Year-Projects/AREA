import 'package:flutter/material.dart';
import 'navigation_destinations.dart';

class NavigationItem {
  final AppDestination destination;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  const NavigationItem({
    required this.destination,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

class AppNavigationItems {
  static const List<NavigationItem> destinations = [
    NavigationItem(
      destination: AppDestination.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: '/dashboard',
    ),
    NavigationItem(
      destination: AppDestination.services,
      label: 'Services',
      icon: Icons.apps_outlined,
      selectedIcon: Icons.apps,
      path: '/services',
    ),
    NavigationItem(
      destination: AppDestination.areas,
      label: 'Areas',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      path: '/areas',
    ),
    NavigationItem(
      destination: AppDestination.profile,
      label: 'Profile',
      icon: Icons.person_outlined,
      selectedIcon: Icons.person,
      path: '/profile',
    ),
  ];

  static NavigationItem? getDestinationFromPath(String path) {
    try {
      return destinations.firstWhere((item) => item.path == path);
    } catch (_) {
      return null;
    }
  }

  static int getIndexFromPath(String path) {
    final item = getDestinationFromPath(path);
    return item != null ? destinations.indexOf(item) : 0;
  }
}