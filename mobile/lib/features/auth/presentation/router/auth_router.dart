import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/accessibility/accessibility_route_announcer.dart';
import '../../../../core/accessibility/accessibility_controller.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../areas/presentation/pages/areas_page.dart';
import '../../../areas/presentation/pages/area_form_page.dart';
import '../../../areas/domain/entities/area.dart';
import '../../../areas/domain/entities/area_template.dart';
import '../../../services/domain/entities/service_component.dart';
import '../../../services/presentation/pages/service_details_page.dart';
import '../../../services/presentation/pages/services_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../blocs/auth_bloc.dart';
import '../pages/email_verification_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/oauth_callback_page.dart';
import '../pages/auth_wrapper_page.dart';

class AuthRouter {
  static List<RouteBase> get routes => [
    ShellRoute(
      observers: [AccessibilityRouteAnnouncer(sl<AccessibilityController>())],
      builder: (context, state, child) {
        return BlocProvider(
          create: (context) => AuthBloc(sl()),
          child: AuthWrapperPage(
            authenticatedChild: NavigationShell(child: child),
          ),
        );
      },
      routes: [
        GoRoute(
          name: 'dashboard',
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          name: 'services',
          path: '/services',
          builder: (context, state) => const ServicesListPage(),
          routes: [
            GoRoute(
              name: 'service-details',
              path: ':serviceId',
              builder: (context, state) {
                final serviceId = state.pathParameters['serviceId']!;
                return ServiceDetailsPage(serviceId: serviceId);
              },
            ),
          ],
        ),
        GoRoute(
          name: 'areas',
          path: '/areas',
          builder: (_, __) => const AreasPage(),
          routes: [
            GoRoute(
              name: 'area-new',
              path: 'new',
              builder: (_, state) {
                final extra = state.extra;
                if (extra is AreaTemplate) {
                  return AreaFormPage(template: extra);
                } else if (extra is ServiceComponent) {
                  return AreaFormPage(initialComponent: extra);
                }
                return const AreaFormPage();
              },
            ),
            GoRoute(
              name: 'area-edit',
              path: 'edit',
              builder: (context, state) {
                final area = state.extra as Area;
                return AreaFormPage(areaToEdit: area);
              },
            ),
          ],
        ),
        GoRoute(
          name: 'profile',
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              name: 'settings',
              path: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      name: 'oauth-callback',
      path: '/oauth/:provider/callback',
      builder: (context, state) {
        final provider = state.pathParameters['provider']!;
        final code = state.uri.queryParameters['code'];
        final error = state.uri.queryParameters['error'];
        final returnTo = state.uri.queryParameters['returnTo'];

        return BlocProvider(
          create: (context) => sl<AuthBloc>(),
          child: OAuthCallbackPage(
            provider: provider,
            code: code,
            error: error,
            returnTo: returnTo,
          ),
        );
      },
    ),

    GoRoute(
      name: 'service-auth-callback',
      path: '/services/:provider/callback',
      builder: (context, state) {
        final provider = state.pathParameters['provider']!;
        final code = state.uri.queryParameters['code'];
        final error = state.uri.queryParameters['error'];
        final returnTo =
            state.uri.queryParameters['returnTo'] ?? '/services/$provider';

        return BlocProvider(
          create: (context) => sl<AuthBloc>(),
          child: OAuthCallbackPage(
            provider: provider,
            code: code,
            error: error,
            returnTo: returnTo,
          ),
        );
      },
    ),

    GoRoute(
      name: 'login',
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (context) => AuthBloc(sl()),
        child: const LoginPage(),
      ),
    ),

    GoRoute(
      name: 'verify-email',
      path: '/verify-email',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        return BlocProvider(
          create: (context) => sl<AuthBloc>(),
          child: EmailVerificationPage(token: token),
        );
      },
    ),

    GoRoute(
      name: 'register',
      path: '/register',
      builder: (context, state) => BlocProvider(
        create: (context) => AuthBloc(sl()),
        child: const RegisterPage(),
      ),
    ),

    GoRoute(
      name: 'root',
      path: '/',
      builder: (context, state) => BlocProvider(
        create: (context) => AuthBloc(sl()),
        child: const AuthWrapperPage(authenticatedChild: SizedBox()),
      ),
    ),
  ];
}
