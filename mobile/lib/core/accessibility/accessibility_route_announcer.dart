import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../navigation/app_navigation.dart';
import 'accessibility_controller.dart';

class AccessibilityRouteAnnouncer extends NavigatorObserver {
  AccessibilityRouteAnnouncer(this._controller);

  final AccessibilityController _controller;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  void _handleRouteChange(Route<dynamic> route) {
    if (route is! PageRoute) return;

    Future<String?> summaryBuilder() async {
      final BuildContext? context =
          route.navigator?.context ?? AppNavigation.navigatorKey.currentContext;
      if (context == null) return null;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return null;
      final state = route.settings.arguments;
      final goState = state is GoRouterState ? state : null;
      return _resolveSummary(
        routeName: route.settings.name,
        l10n: l10n,
        state: goState,
      );
    }

    _controller.setCurrentSummaryProvider(summaryBuilder);

    if (!_controller.isScreenReaderEnabled) return;

    unawaited(
      summaryBuilder().then((summary) async {
        if (summary == null || summary.trim().isEmpty) return;
        await _controller.announce(summary);
      }),
    );
  }

  String? _resolveSummary({
    required String? routeName,
    required AppLocalizations l10n,
    GoRouterState? state,
  }) {
    switch (routeName) {
      case 'dashboard':
        return l10n.dashboardHeaderTitle;
      case 'services':
        return l10n.services;
      case 'service-details':
        final serviceId = state?.pathParameters['serviceId'];
        return serviceId != null
            ? '${l10n.services}: $serviceId'
            : l10n.services;
      case 'areas':
        return l10n.myAreas;
      case 'area-new':
        return l10n.newArea;
      case 'area-edit':
        return l10n.editArea;
      case 'profile':
        return l10n.profile;
      case 'settings':
        return l10n.settingsPageTitle;
      case 'login':
        return l10n.login;
      case 'register':
        return l10n.signUp;
      case 'verify-email':
        return l10n.verifyingYourEmail;
      case 'oauth-callback':
      case 'service-auth-callback':
        return l10n.redirectingToDashboard;
      case 'root':
        return l10n.appTitle;
      default:
        return routeName;
    }
  }
}
