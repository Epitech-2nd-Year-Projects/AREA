import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/entities/service_with_status.dart';
import '../../domain/value_objects/service_category.dart';

class ServiceCard extends StatelessWidget {
  final ServiceWithStatus service;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: AppColors.primary.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildServiceIcon(),
              const SizedBox(height: AppSpacing.md),
              _buildTitle(context),
              const SizedBox(height: AppSpacing.sm),
              _buildCategory(context),
              const SizedBox(height: AppSpacing.sm),
              _buildSubscriptionIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          service.provider.displayName[0].toUpperCase(),
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      service.provider.displayName,
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.getTextPrimaryColor(context),
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCategory(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        service.provider.category.displayName,
        style: AppTypography.labelMedium.copyWith(
          color: _getCategoryColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubscriptionIndicator() {
    if (!service.isSubscribed) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 14,
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (service.provider.category) {
      case ServiceCategory.social:
        return const Color(0xFF4267B2);
      case ServiceCategory.productivity:
        return const Color(0xFF34A853);
      case ServiceCategory.communication:
        return const Color(0xFFFF6B35);
      case ServiceCategory.storage:
        return const Color(0xFF0F9D58);
      case ServiceCategory.automation:
        return const Color(0xFF9C27B0);
      case ServiceCategory.other:
        return AppColors.gray500;
    }
  }
}