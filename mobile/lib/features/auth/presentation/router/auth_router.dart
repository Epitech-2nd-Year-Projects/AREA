import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../areas/presentation/pages/areas_page.dart';
import '../../../areas/presentation/pages/area_form_page.dart';
import '../../../areas/domain/entities/area.dart';
import '../blocs/auth_bloc.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/oauth_callback_page.dart';
import '../pages/auth_wrapper_page.dart';

class AuthRouter {
  static List<RouteBase> get routes => [
    ShellRoute(
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
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServicesPage(),
        ),
        GoRoute(
          path: '/areas',
          builder: (context, state) => const AreasPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const AreaFormPage(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final area = state.extra as Area; // on reçoit l'Area à éditer
                return AreaFormPage(areaToEdit: area);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/oauth/callback/:provider',
      builder: (context, state) {
        final provider = state.pathParameters['provider']!;
        final code = state.uri.queryParameters['code'];
        final error = state.uri.queryParameters['error'];

        return OAuthCallbackPage(
          provider: provider,
          code: code,
          error: error,
        );
      },
    ),

    GoRoute(
      path: '/',
      redirect: (context, state) {
        return '/services';
      },
    ),
  ];
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const  Center(
      child: Text('Dashboard Page 🚀'),
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Services Page 🔌'),
    );
  }
}

// class AreasPage extends StatelessWidget {
//   const AreasPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text('Areas Page ⚡'),
//     );
//   }
// }

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Page 👤'),
    );
  }
}