import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/service_provider.dart';
import '../../domain/entities/user_service_subscription.dart';

class ServiceSubscriptionButton extends StatelessWidget {
  final ServiceProvider service;
  final UserServiceSubscription? subscription;
  final bool isLoading;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;

  const ServiceSubscriptionButton({
    super.key,
    required this.service,
    this.subscription,
    required this.isLoading,
    required this.onSubscribe,
    required this.onUnsubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSubscribed = subscription?.isActive ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isSubscribed ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : (isSubscribed ? onUnsubscribe : onSubscribe),
            icon: isLoading
                ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(
              isSubscribed ? Icons.remove_circle_rounded : Icons.add_circle_rounded,
              size: constraints.maxWidth < 120 ? 14 : 16,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isSubscribed ? l10n.unsubscribe : l10n.subscribe,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: constraints.maxWidth < 120 ? 11 : null,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSubscribed ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 120 ? AppSpacing.sm : AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              minimumSize: const Size(0, 36),
            ),
          ),
        );
      },
    );
  }
}