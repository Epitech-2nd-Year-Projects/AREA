import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/email_verification/email_verification_cubit.dart';
import '../blocs/email_verification/email_verification_state.dart';

class EmailVerificationPage extends StatefulWidget {
  final String? token;

  const EmailVerificationPage({super.key, this.token});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<EmailVerificationCubit>().verifyEmail(widget.token!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => EmailVerificationCubit(sl()),
      child: BlocListener<EmailVerificationCubit, EmailVerificationState>(
        listener: (context, state) {
          if (state is EmailVerificationSuccess) {
            context.read<AuthBloc>().add(UserLoggedIn(state.user));
            context.go('/dashboard');
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.getBackgroundColor(context),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child:
                    BlocBuilder<EmailVerificationCubit, EmailVerificationState>(
                      builder: (context, state) {
                        if (state is EmailVerificationInitial) {
                          return _buildInitialState(context, l10n);
                        } else if (state is EmailVerificationLoading) {
                          return _buildLoadingState(context, l10n);
                        } else if (state is EmailVerificationSuccess) {
                          return _buildSuccessState(context, l10n);
                        } else if (state is EmailVerificationError) {
                          return _buildErrorState(context, l10n, state.message);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.email_outlined, size: 80, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.checkYourEmail,
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.weVeSentVerificationLink,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getTextSecondaryColor(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
          child: const Text('Go to Login'),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.verifyingYourEmail,
          style: AppTypography.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.emailVerified,
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.redirectingToDashboard,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getTextSecondaryColor(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.error,
            size: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.verificationFailed,
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getTextSecondaryColor(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
          child: Text(l10n.backToLogin),
        ),
      ],
    );
  }
}
