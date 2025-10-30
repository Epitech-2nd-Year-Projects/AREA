import 'package:flutter/material.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../core/design_system/app_spacing.dart';

class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.getDividerColor(context),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.getDividerColor(context),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
