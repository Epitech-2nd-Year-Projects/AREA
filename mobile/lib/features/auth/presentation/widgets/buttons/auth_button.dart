import 'package:flutter/material.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../core/design_system/app_spacing.dart';

enum AuthButtonVariant { primary, secondary, outline }

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AuthButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AuthButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(context),
        child: isLoading
            ? _buildLoadingWidget(context)
            : _buildButtonContent(context),
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (variant) {
      case AuthButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case AuthButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.getSurfaceVariantColor(context),
          foregroundColor: AppColors.getTextPrimaryColor(context),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case AuthButtonVariant.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.getSurfaceColor(context),
          foregroundColor: AppColors.getTextPrimaryColor(context),
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: AppColors.getBorderColor(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
    }
  }

  Widget _buildLoadingWidget(BuildContext context) {
    Color indicatorColor = variant == AuthButtonVariant.primary
        ? AppColors.white
        : AppColors.primary;

    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: AppTypography.labelLarge.copyWith(
              color: _getTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(
        color: _getTextColor(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Color _getTextColor(BuildContext context) {
    switch (variant) {
      case AuthButtonVariant.primary:
        return AppColors.white;
      case AuthButtonVariant.secondary:
      case AuthButtonVariant.outline:
        return AppColors.getTextPrimaryColor(context);
    }
  }
}
