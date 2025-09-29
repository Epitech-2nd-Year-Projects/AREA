import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/entities/service_provider.dart';

class ServiceInfoCard extends StatelessWidget {
  final ServiceProvider service;

  const ServiceInfoCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isExtremelyCompact = constraints.maxWidth < 250;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isExtremelyCompact)
                _buildCompactHeader(context)
              else
                _buildNormalHeader(context, constraints.maxWidth),
              const SizedBox(height: AppSpacing.xl),
              _buildAuthenticationSection(context, constraints.maxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildServiceIcon(context, 50),
        const SizedBox(height: AppSpacing.md),
        Text(
          service.displayName,
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _buildCategoryChip(context, true),
            _buildStatusBadge(context, true),
          ],
        ),
      ],
    );
  }

  Widget _buildNormalHeader(BuildContext context, double width) {
    final isSmall = width < 350;
    final isMedium = width < 450;

    final iconSize = isSmall ? 60.0 : isMedium ? 68.0 : 76.0;
    final titleFontSize = isSmall ? 20.0 : isMedium ? 22.0 : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildServiceIcon(context, iconSize),
        SizedBox(width: isSmall ? AppSpacing.md : AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.displayName,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildBadges(context, width),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceIcon(BuildContext context, double size) {
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          service.displayName[0].toUpperCase(),
          style: AppTypography.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }

  Widget _buildBadges(BuildContext context, double width) {
    final isSmall = width < 350;

    final categoryChip = _buildCategoryChip(context, isSmall);
    final statusBadge = _buildStatusBadge(context, isSmall);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [categoryChip, statusBadge],
    );
  }

  Widget _buildCategoryChip(BuildContext context, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        service.category.displayName,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: isSmall ? 12 : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isSmall) {
    final isActive = service.isEnabled;
    final statusColor = isActive ? AppColors.success : AppColors.error;
    final statusText = isActive ? 'Active' : 'Inactive';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            statusText,
            style: AppTypography.labelLarge.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 12 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationSection(BuildContext context, double width) {
    final authInfo = _getAuthInfo();
    final isSmall = width < 350;

    return Container(
      padding: EdgeInsets.all(isSmall ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? AppSpacing.sm : AppSpacing.md),
            decoration: BoxDecoration(
              color: authInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              authInfo.icon,
              color: authInfo.color,
              size: isSmall ? 16 : 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Authentication',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.getTextSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                    fontSize: isSmall ? 12 : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  authInfo.text,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 14 : null,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? AppSpacing.xs : AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: authInfo.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              authInfo.badge,
              style: AppTypography.labelMedium.copyWith(
                color: authInfo.color,
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 11 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, IconData icon, String text, String badge}) _getAuthInfo() {
    switch (service.oauthType.value) {
      case 'oauth2':
        return (
        color: AppColors.primary,
        icon: Icons.security_rounded,
        text: 'OAuth 2.0 Required',
        badge: 'OAuth'
        );
      case 'apikey':
        return (
        color: AppColors.warning,
        icon: Icons.key_rounded,
        text: 'API Key Required',
        badge: 'API Key'
        );
      case 'none':
        return (
        color: AppColors.success,
        icon: Icons.public_rounded,
        text: 'No Authentication',
        badge: 'Public'
        );
      default:
        return (
        color: AppColors.gray500,
        icon: Icons.help_outline_rounded,
        text: 'Unknown Authentication',
        badge: 'Unknown'
        );
    }
  }
}