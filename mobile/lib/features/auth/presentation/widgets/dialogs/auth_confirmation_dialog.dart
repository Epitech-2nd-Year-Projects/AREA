import 'package:flutter/material.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../core/design_system/app_spacing.dart';
import '../buttons/auth_button.dart';

class AuthConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AuthConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: AppColors.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  child: Text(
                    cancelText,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AuthButton(
                  text: confirmText,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  width: 120,
                  variant: isDestructive
                      ? AuthButtonVariant.primary
                      : AuthButtonVariant.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmText,
        String cancelText = 'Cancel',
        bool isDestructive = false,
      }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AuthConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}