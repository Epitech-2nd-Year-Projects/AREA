import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import 'dashboard_card.dart';

class ServicesSummaryCard extends StatelessWidget {
  final DashboardServicesSummary summary;
  final VoidCallback onTap;

  const ServicesSummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apps, color: AppColors.primary, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardServicesSummaryTitle,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.dashboardServicesSummarySubtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _SummaryMetric(
                value: summary.connected,
                label: l10n.dashboardServicesSummaryConnected,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryMetric(
                value: summary.expiringSoon,
                label: l10n.dashboardServicesSummaryExpiringSoon,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.lg),
              _SummaryMetric(
                value: summary.totalAvailable,
                label: l10n.dashboardServicesSummaryTotalAvailable,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: AppTypography.displayMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
