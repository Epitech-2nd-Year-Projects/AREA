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
import '../blocs/login/login_cubit.dart';
import '../blocs/login/login_state.dart';
import '../blocs/oauth/oauth_cubit.dart';
import '../blocs/oauth/oauth_state.dart';
import '../widgets/forms/login_form.dart';
import '../widgets/buttons/oauth_provider_button.dart';
import '../widgets/common/auth_divider.dart';
import '../../domain/entities/oauth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginCubit(sl())),
        BlocProvider(create: (_) => OAuthCubit()),
      ],
      child: const _LoginPageContent(),
    );
  }
}

class _LoginPageContent extends StatelessWidget {
  const _LoginPageContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccess) {
                context.read<AuthBloc>().add(UserLoggedIn(state.user));
                context.go('/dashboard');
              } else if (state is LoginError) {
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
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  /*ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not launch OAuth login'),
                      backgroundColor: AppColors.error,
                    ),
                  );*/
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
                    const SizedBox(height: AppSpacing.xl),
                    _buildHeader(context, l10n),
                    const SizedBox(height: AppSpacing.xxl),
                    const LoginForm(),
                    const SizedBox(height: AppSpacing.xl),
                    AuthDivider(text: l10n.continueWith),
                    const SizedBox(height: AppSpacing.xl),
                    _buildOAuthButtons(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSignUpPrompt(context, l10n),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeBack,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.signInToAccount,
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
        onPressed: () =>
            context.read<OAuthCubit>().startOAuth(OAuthProvider.google),
      ),
    ],
  );

  Widget _buildSignUpPrompt(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.dontHaveAnAccount,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/register'),
            child: Text(
              l10n.signUp,
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
