import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/entities/user_service_subscription.dart';
import '../../domain/value_objects/subscription_status.dart';

class SubscriptionStatusBadge extends StatelessWidget {
  final bool isSubscribed;
  final UserServiceSubscription? subscription;

  const SubscriptionStatusBadge({
    super.key,
    required this.isSubscribed,
    this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSubscribed) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Available',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.gray700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final status = subscription?.status ?? SubscriptionStatus.active;
    final (color, backgroundColor, text) = _getStatusProperties(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _getStatusProperties(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return (
        AppColors.success,
        AppColors.success.withValues(alpha: 0.1),
        'Active'
        );
      case SubscriptionStatus.expired:
        return (
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.1),
        'Expired'
        );
      case SubscriptionStatus.revoked:
        return (
        AppColors.error,
        AppColors.error.withValues(alpha: 0.1),
        'Revoked'
        );
      case SubscriptionStatus.needsConsent:
        return (
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.1),
        'Action Required'
        );
    }
  }
}