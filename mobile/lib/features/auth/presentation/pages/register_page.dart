import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
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
        BlocProvider(create: (context) => OAuthCubit()),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<RegisterCubit, RegisterState>(
            listener: (context, state) {
              if (state is RegisterSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.accountCreatedSuccess),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 5),
                  ),
                );
                context.go('/verify-email');
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
                  if (!context.mounted) return;
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.couldNotLaunchOAuth),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } else if (state is OAuthSuccess) {
                context.read<AuthBloc>().add(UserLoggedIn(state.user));
                context.go('/dashboard');
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
                    _buildHeader(context, l10n),
                    const SizedBox(height: AppSpacing.xl),
                    const RegisterForm(),
                    const SizedBox(height: AppSpacing.lg),
                    AuthDivider(text: l10n.orSignUpWith),
                    const SizedBox(height: AppSpacing.lg),
                    _buildOAuthButtons(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildLoginPrompt(context, l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.createAccount,
          style: AppTypography.displayMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.joinAreaToAutomate,
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
    ],
  );

  Widget _buildLoginPrompt(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.alreadyHaveAccount,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              l10n.signInLink,
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