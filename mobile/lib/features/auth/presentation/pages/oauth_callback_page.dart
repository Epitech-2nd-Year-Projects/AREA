import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';

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

    // Cette page ne devrait normalement plus être utilisée
    // car le deep linking gère automatiquement le callback
    // Mais on la garde au cas où pour fallback

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleFallback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
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
                'Processing sign in...',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You\'ll be redirected shortly',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFallback() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (widget.error != null) {
          context.go('/login');
        } else {
          context.go('/login');
        }
      }
    });
  }
}