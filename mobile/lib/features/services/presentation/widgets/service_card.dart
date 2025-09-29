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
      splashColor: AppColors.primary.withValues(alpha: 0.1),
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
              color: AppColors.gray200.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isSmall = width < 160;
            final iconSize = isSmall ? 48.0 : 56.0;
            final titleFontSize = isSmall ? 15.0 : 16.0;
            final categoryFontSize = isSmall ? 11.0 : 12.0;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildServiceIcon(iconSize),
                  const SizedBox(height: AppSpacing.md),
                  _buildTitle(context, titleFontSize),
                  const SizedBox(height: AppSpacing.sm),
                  _buildCategory(context, categoryFontSize),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          service.provider.displayName[0].toUpperCase(),
          style: AppTypography.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, double fontSize) {
    return Text(
      service.provider.displayName,
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.getTextPrimaryColor(context),
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCategory(BuildContext context, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        service.provider.category.displayName,
        style: AppTypography.labelLarge.copyWith(
          color: _getCategoryColor(),
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubscriptionIndicator() {
    if (!service.isSubscribed) {
      return const SizedBox(height: 20);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Subscribed',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (service.provider.category) {
      case ServiceCategory.social:
        return const Color(0xFF1877F2); // Facebook Blue
      case ServiceCategory.productivity:
        return const Color(0xFF34A853); // Google Green
      case ServiceCategory.communication:
        return const Color(0xFFFF6B35); // Orange
      case ServiceCategory.storage:
        return const Color(0xFF0F9D58); // Drive Green
      case ServiceCategory.automation:
        return const Color(0xFF9C27B0); // Purple
      case ServiceCategory.other:
        return AppColors.gray600;
    }
  }
}