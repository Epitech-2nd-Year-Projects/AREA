import 'package:flutter/material.dart';

enum AppDestination { dashboard, services, areas, profile }

extension AppDestinationExtension on AppDestination {
  String get label {
    switch (this) {
      case AppDestination.dashboard:
        return 'Dashboard';
      case AppDestination.services:
        return 'Services';
      case AppDestination.areas:
        return 'Areas';
      case AppDestination.profile:
        return 'Profile';
    }
  }

  IconData get icon {
    switch (this) {
      case AppDestination.dashboard:
        return Icons.dashboard_outlined;
      case AppDestination.services:
        return Icons.apps_outlined;
      case AppDestination.areas:
        return Icons.auto_awesome_outlined;
      case AppDestination.profile:
        return Icons.person_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case AppDestination.dashboard:
        return Icons.dashboard;
      case AppDestination.services:
        return Icons.apps;
      case AppDestination.areas:
        return Icons.auto_awesome;
      case AppDestination.profile:
        return Icons.person;
    }
  }

  String get path {
    switch (this) {
      case AppDestination.dashboard:
        return '/dashboard';
      case AppDestination.services:
        return '/services';
      case AppDestination.areas:
        return '/areas';
      case AppDestination.profile:
        return '/profile';
    }
  }
}
