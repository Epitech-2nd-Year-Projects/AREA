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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _getCategoryColor(isDark).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor(isDark).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        service.provider.category.displayName,
        style: AppTypography.labelLarge.copyWith(
          color: _getCategoryColor(isDark),
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getCategoryColor(bool isDark) {
    switch (service.provider.category) {
      case ServiceCategory.social:
        return AppColors.social;
      case ServiceCategory.productivity:
        return AppColors.productivity;
      case ServiceCategory.communication:
        return AppColors.communication;
      case ServiceCategory.storage:
        return AppColors.storage;
      case ServiceCategory.automation:
        return AppColors.automation;
      case ServiceCategory.other:
        return isDark ? AppColors.otherDark : AppColors.otherWhite;
    }
  }
}