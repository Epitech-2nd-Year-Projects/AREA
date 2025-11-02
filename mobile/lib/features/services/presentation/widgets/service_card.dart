import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/entities/service_with_status.dart';
import '../../domain/value_objects/service_category.dart';
import 'staggered_animations.dart';
import 'service_logo.dart';

class ServiceCard extends StatelessWidget {
  final ServiceWithStatus service;
  final VoidCallback onTap;
  final int delay;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(
      delay: delay,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.getSurfaceColor(context),
                AppColors.getSurfaceColor(context).withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
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

              return Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
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
                    ),
                  ),
                  if (service.isSubscribed)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _buildSubscribedBadge(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon(double size) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: 0.8 + (scale * 0.2),
          child: ServiceLogo(
            serviceName: service.provider.displayName,
            size: size,
          ),
        );
      },
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
    final categoryColor = _getCategoryColor(isDark);

    return FadeInAnimation(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              categoryColor.withValues(alpha: 0.15),
              categoryColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.4),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          service.provider.category.displayName,
          style: AppTypography.labelLarge.copyWith(
            color: categoryColor,
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
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
      case ServiceCategory.development:
        return AppColors.automation;
      case ServiceCategory.other:
        return isDark ? AppColors.otherDark : AppColors.otherWhite;
    }
  }

  Widget _buildSubscribedBadge() {
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Icon(
        Icons.verified_rounded,
        size: 14,
        color: AppColors.success,
      ),
    );
  }
}
