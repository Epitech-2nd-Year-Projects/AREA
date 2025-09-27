import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
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
    final isSubscribed = subscription?.isActive ?? false;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : (isSubscribed ? onUnsubscribe : onSubscribe),
      icon: isLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Icon(
        isSubscribed ? Icons.remove_circle : Icons.add_circle,
        size: 18,
      ),
      label: Text(isSubscribed ? 'Unsubscribe' : 'Subscribe'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubscribed ? AppColors.error : AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}