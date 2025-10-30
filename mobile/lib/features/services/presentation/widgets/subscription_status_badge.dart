import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/entities/user_service_subscription.dart';
import '../../domain/value_objects/subscription_status.dart';
import 'staggered_animations.dart';

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
      return FadeInAnimation(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gray200.withValues(alpha: 0.8),
                AppColors.gray200.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gray300.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray200.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
        ),
      );
    }

    final status = subscription?.status ?? SubscriptionStatus.active;
    final (color, backgroundColor, text) = _getStatusProperties(status);

    return FadeInAnimation(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, backgroundColor.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                ],
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
      ),
    );
  }

  (Color, Color, String) _getStatusProperties(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return (
          AppColors.success,
          AppColors.success.withValues(alpha: 0.1),
          'Active',
        );
      case SubscriptionStatus.expired:
        return (
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.1),
          'Expired',
        );
      case SubscriptionStatus.revoked:
        return (
          AppColors.error,
          AppColors.error.withValues(alpha: 0.1),
          'Revoked',
        );
      case SubscriptionStatus.needsConsent:
        return (
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.1),
          'Action Required',
        );
    }
  }
}
