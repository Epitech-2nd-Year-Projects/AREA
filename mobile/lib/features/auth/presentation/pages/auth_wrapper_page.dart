import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'login_page.dart';

class AuthWrapperPage extends StatefulWidget {
  final Widget authenticatedChild;

  const AuthWrapperPage({
    super.key,
    required this.authenticatedChild,
  });

  @override
  State<AuthWrapperPage> createState() => _AuthWrapperPageState();
}

class _AuthWrapperPageState extends State<AuthWrapperPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AppStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLocation = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          debugPrint('🔓 User is unauthenticated');
        } else if (state is Authenticated) {
          debugPrint('🔒 User is authenticated: ${state.user.email}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && currentLocation == '/') {
              context.go('/dashboard');
            }
          });
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return _buildLoadingScreen(theme, l10n);
        }

        if (state is Authenticated) {
          if (currentLocation == '/') {
            return _buildLoadingScreen(theme, l10n);
          }
          return widget.authenticatedChild;
        }

        if (state is Unauthenticated) {
          return _buildUnauthenticatedView();
        }

        if (state is AuthError) {
          return _buildErrorScreen(theme, l10n, state.message);
        }

        return _buildLoadingScreen(theme, l10n);
      },
    );
  }

  Widget _buildLoadingScreen(ThemeData theme, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(l10n.loading),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return const LoginPage();
  }

  Widget _buildErrorScreen(ThemeData theme, AppLocalizations l10n, String message) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.authenticationError,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AppStarted());
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}