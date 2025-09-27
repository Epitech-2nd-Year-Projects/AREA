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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildServiceIcon(context),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.displayName,
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildCategoryChip(context),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoSection(context, 'Authentication', _getAuthText()),
          const SizedBox(height: AppSpacing.md),
          _buildInfoSection(context, 'Status', service.isEnabled ? 'Active' : 'Inactive'),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          service.displayName[0].toUpperCase(),
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        service.category.displayName,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
        ),
      ],
    );
  }

  String _getAuthText() {
    switch (service.oauthType.value) {
      case 'oauth2':
        return 'OAuth 2.0 Required';
      case 'apikey':
        return 'API Key Required';
      case 'none':
        return 'No Authentication';
      default:
        return 'Unknown';
    }
  }
}