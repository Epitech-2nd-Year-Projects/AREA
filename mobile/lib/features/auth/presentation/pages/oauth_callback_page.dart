import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class OAuthCallbackPage extends StatefulWidget {
  final String provider;
  final String? code;
  final String? error;
  final String? returnTo;

  const OAuthCallbackPage({
    super.key,
    required this.provider,
    this.code,
    this.error,
    this.returnTo,
  });

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  bool _hasNavigated = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processCallback();
    });
  }

  Future<void> _processCallback() async {
    if (_isProcessing || _hasNavigated) return;

    if (widget.error != null) {
      _navigateToLogin();
      return;
    }

    if (widget.code == null) {
      _navigateToLogin();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    context.read<AuthBloc>().add(AppStarted());

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;

    if (authState is Authenticated) {
      _navigateAfterSuccess();
    } else {
      _navigateToLogin();
    }
  }

  void _navigateAfterSuccess() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
      context.go(widget.returnTo!);
    } else {
      context.go('/dashboard');
    }
  }

  void _navigateToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.error != null) {
      return _buildErrorState(context, l10n);
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_hasNavigated) return;

        if (state is Authenticated) {
          _navigateAfterSuccess();
        } else if (state is AuthError) {
          _navigateToLogin();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildLoadingState(context, l10n),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.completingSignIn,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.pleaseWaitWhileWeAuthenticateYou,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
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
              l10n.authenticationFailed,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.error ?? l10n.unknownErrorOccurred,
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
        ),
      ),
    );
  }
}
