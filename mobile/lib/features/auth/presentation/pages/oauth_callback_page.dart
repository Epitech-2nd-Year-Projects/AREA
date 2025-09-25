import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/oauth/oauth_cubit.dart';
import '../blocs/oauth/oauth_state.dart';
import '../../domain/entities/oauth_provider.dart';

class OAuthCallbackPage extends StatefulWidget {
  final String provider;
  final String? code;
  final String? error;

  const OAuthCallbackPage({
    super.key,
    required this.provider,
    this.code,
    this.error,
  });

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => OAuthCubit(sl()),
      child: BlocListener<OAuthCubit, OAuthState>(
        listener: (context, state) {
          if (state is OAuthSuccess) {
            context.read<AuthBloc>().add(UserLoggedIn(state.session.user));
            context.go('/dashboard');
          } else if (state is OAuthError) {
            _showErrorDialog(context, state.message);
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: BlocBuilder<OAuthCubit, OAuthState>(
            builder: (context, state) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusWidget(context, state),
                      const SizedBox(height: AppSpacing.xl),
                      _buildStatusText(context, state),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context, OAuthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state is OAuthCallbackReceived || state is OAuthInitial) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
        ),
      );
    } else if (state is OAuthSuccess) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.success,
          size: 40,
        ),
      );
    } else if (state is OAuthError) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.error,
          size: 40,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusText(BuildContext context, OAuthState state) {
    String title;
    String subtitle;

    if (state is OAuthCallbackReceived || state is OAuthInitial) {
      title = 'Completing sign in...';
      subtitle = 'Please wait while we verify your account';
    } else if (state is OAuthSuccess) {
      title = 'Success!';
      subtitle = 'You\'ve been signed in successfully';
    } else if (state is OAuthError) {
      title = 'Something went wrong';
      subtitle = state.message;
    } else {
      title = 'Processing...';
      subtitle = 'Please wait';
    }

    return Column(
      children: [
        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getTextSecondaryColor(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleCallback() {
    if (widget.error != null) {
      context.read<OAuthCubit>().emit(
        OAuthError('OAuth authorization failed: ${widget.error}'),
      );
      return;
    }

    if (widget.code == null) {
      context.read<OAuthCubit>().emit(
        const OAuthError('No authorization code received'),
      );
      return;
    }

    final provider = _parseProvider(widget.provider);
    if (provider != null) {
      context.read<OAuthCubit>().handleCallback(provider, widget.code!);
    } else {
      context.read<OAuthCubit>().emit(
        OAuthError('Unsupported OAuth provider: ${widget.provider}'),
      );
    }
  }

  OAuthProvider? _parseProvider(String providerString) {
    switch (providerString.toLowerCase()) {
      case 'google':
        return OAuthProvider.google;
      case 'facebook':
        return OAuthProvider.facebook;
      case 'apple':
        return OAuthProvider.apple;
      default:
        return null;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sign In Failed',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: Text(
              'Try Again',
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}