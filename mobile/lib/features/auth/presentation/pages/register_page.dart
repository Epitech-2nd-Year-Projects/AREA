import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../blocs/oauth/oauth_cubit.dart';
import '../blocs/oauth/oauth_state.dart';
import '../blocs/register/register_cubit.dart';
import '../blocs/register/register_state.dart';
import '../widgets/forms/register_form.dart';
import '../widgets/common/auth_divider.dart';
import '../widgets/buttons/oauth_provider_button.dart';
import '../../domain/entities/oauth_provider.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => RegisterCubit(sl())),
        BlocProvider(create: (context) => OAuthCubit(sl())),
      ],
      child: const _RegisterPageContent(),
    );
  }
}

class _RegisterPageContent extends StatelessWidget {
  const _RegisterPageContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<RegisterCubit, RegisterState>(
            listener: (context, state) {
              if (state is RegisterSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account created! Please check your email to confirm.'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.go('/login');
              } else if (state is RegisterError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
          BlocListener<OAuthCubit, OAuthState>(
            listener: (context, state) async {
              if (state is OAuthRedirectReady) {
                final url = Uri.parse(state.redirectUrl.toString());
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not launch OAuth register'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } else if (state is OAuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    _buildHeader(context),
                    const SizedBox(height: AppSpacing.xl),
                    const RegisterForm(),
                    const SizedBox(height: AppSpacing.lg),
                    const AuthDivider(text: 'or sign up with'),
                    const SizedBox(height: AppSpacing.lg),
                    _buildOAuthButtons(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildLoginPrompt(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create account',
          style: AppTypography.displayMedium.copyWith(
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Join AREA to automate your digital life',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildOAuthButtons(BuildContext context) => Column(
    children: [
      OAuthProviderButton(
        provider: OAuthProvider.google,
        onPressed: () => context.read<OAuthCubit>().startOAuth(OAuthProvider.google),
      ),
      const SizedBox(height: AppSpacing.md),
      OAuthProviderButton(
        provider: OAuthProvider.apple,
        onPressed: () => context.read<OAuthCubit>().startOAuth(OAuthProvider.apple),
      ),
      const SizedBox(height: AppSpacing.md),
      OAuthProviderButton(
        provider: OAuthProvider.facebook,
        onPressed: () => context.read<OAuthCubit>().startOAuth(OAuthProvider.facebook),
      ),
    ],
  );

  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              'Sign in',
              style: AppTypography.bodyMedium.copyWith(
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