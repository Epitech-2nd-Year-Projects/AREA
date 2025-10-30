import 'package:flutter/material.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../core/design_system/app_spacing.dart';
import '../buttons/auth_button.dart';

class AuthErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;

  const AuthErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
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
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AuthButton(
                text: retryText ?? 'Try Again',
                onPressed: onRetry,
                variant: AuthButtonVariant.outline,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
