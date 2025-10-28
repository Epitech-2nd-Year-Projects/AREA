import 'package:flutter/material.dart';
import '../../../domain/entities/oauth_provider.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../core/design_system/app_spacing.dart';

class OAuthProviderButton extends StatelessWidget {
  final OAuthProvider provider;
  final VoidCallback onPressed;
  final bool isLoading;

  const OAuthProviderButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.getSurfaceColor(context),
          foregroundColor: AppColors.getTextPrimaryColor(context),
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: AppColors.getBorderColor(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getProviderIcon(isDark),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      'Continue with ${_getProviderName()}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _getProviderIcon(bool isDark) {
    switch (provider) {
      case OAuthProvider.google:
        return Image.asset('assets/icons/google.png', width: 24, height: 24);
      case OAuthProvider.facebook:
        return Image.asset('assets/icons/facebook.png', width: 24, height: 24);
      case OAuthProvider.apple:
        return Image.asset(
          isDark ? 'assets/icons/applel.png' : 'assets/icons/apple.png',
          width: 24,
          height: 24,
        );
    }
  }

  String _getProviderName() {
    switch (provider) {
      case OAuthProvider.google:
        return 'Google';
      case OAuthProvider.facebook:
        return 'Facebook';
      case OAuthProvider.apple:
        return 'Apple';
    }
  }
}
