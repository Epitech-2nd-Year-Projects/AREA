import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import 'dashboard_card.dart';

class SystemStatusCard extends StatelessWidget {
  final DashboardSystemStatus status;
  final VoidCallback onRetry;

  const SystemStatusCard({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReachable = status.isReachable;
    final icon = isReachable ? Icons.check_circle : Icons.error_outline;
    final iconColor = isReachable ? AppColors.success : AppColors.error;
    final textColor = AppColors.getTextPrimaryColor(context);
    final secondaryColor = AppColors.getTextSecondaryColor(context);

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 28,
                semanticLabel: l10n.dashboardSystemStatusSemanticLabel,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardSystemStatusTitle,
                      style: AppTypography.headlineMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isReachable
                          ? l10n.dashboardSystemStatusOnlineMessage
                          : (status.message ??
                              l10n.dashboardSystemStatusOfflineMessage),
                      style: AppTypography.bodyMedium.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatusMetric(
                label: l10n.dashboardSystemStatusReachability,
                value: isReachable
                    ? l10n.dashboardSystemStatusOnline
                    : l10n.dashboardSystemStatusOffline,
                valueColor: iconColor,
              ),
              const SizedBox(width: AppSpacing.lg),
              _StatusMetric(
                label: l10n.dashboardSystemStatusLastPing,
                value: status.lastPingMs > 0 ? '${status.lastPingMs} ms' : '—',
              ),
              const SizedBox(width: AppSpacing.lg),
              _StatusMetric(
                label: l10n.dashboardSystemStatusLastSync,
                value: _formatTimestamp(context, status.lastSyncedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.day == now.day &&
        timestamp.month == now.month &&
        timestamp.year == now.year) {
      final timeOfDay = TimeOfDay.fromDateTime(timestamp);
      final localizations = MaterialLocalizations.of(context);
      final alwaysUse24HourFormat =
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
      return localizations.formatTimeOfDay(
        timeOfDay,
        alwaysUse24HourFormat: alwaysUse24HourFormat,
      );
    }
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatShortDate(timestamp);
  }
}

class _StatusMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              color: valueColor ?? AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
