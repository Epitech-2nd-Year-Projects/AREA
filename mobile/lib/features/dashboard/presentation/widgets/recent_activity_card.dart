import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import 'dashboard_card.dart';

class RecentActivityCard extends StatelessWidget {
  final List<DashboardActivity> activities;

  const RecentActivityCard({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardRecentActivityTitle,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.dashboardRecentActivitySubtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (activities.isEmpty)
            Text(
              l10n.dashboardRecentActivityEmpty,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < activities.length; index++) ...[
                  if (index != 0)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(
                        height: 1,
                        color: AppColors.getDividerColor(context).withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  _ActivityRow(activity: activities[index]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final DashboardActivity activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = _statusLabel(activity.status, l10n);
    final statusColor = _statusColor(activity);
    final statusIcon = _statusIcon(activity);

    final metadata = _buildMetadataText(activity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.areaName,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                metadata,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: AppTypography.labelMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _buildMetadataText(DashboardActivity activity) {
    final buffer = <String>[];

    buffer.add(activity.serviceName);

    final timestamp = DateFormat('MMM d · HH:mm').format(
      activity.completedAt.toLocal(),
    );
    buffer.add(timestamp);

    final durationLabel = _formatDuration(activity.duration);
    if (durationLabel != null) {
      buffer.add(durationLabel);
    }

    return buffer.join(' • ');
  }

  static String _statusLabel(String status, AppLocalizations l10n) {
    final normalized = status.toLowerCase();
    if (normalized == 'succeeded') {
      return l10n.dashboardRecentActivityStatusSucceeded;
    }
    if (normalized == 'failed' || normalized == 'errored' || normalized == 'error') {
      return l10n.dashboardRecentActivityStatusFailed;
    }
    if (normalized.isEmpty) {
      return status;
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  static Color _statusColor(DashboardActivity activity) {
    if (activity.wasSuccessful) {
      return AppColors.success;
    }
    final normalized = activity.status.toLowerCase();
    if (normalized == 'failed' || normalized == 'errored' || normalized == 'error') {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  static IconData _statusIcon(DashboardActivity activity) {
    if (activity.wasSuccessful) {
      return Icons.check_circle_rounded;
    }
    final normalized = activity.status.toLowerCase();
    if (normalized == 'failed' || normalized == 'errored' || normalized == 'error') {
      return Icons.error_outline_rounded;
    }
    return Icons.schedule_rounded;
  }

  static String? _formatDuration(Duration duration) {
    final effective = duration.isNegative ? duration.abs() : duration;
    if (effective.inSeconds <= 0) {
      return null;
    }
    if (effective.inMinutes >= 1) {
      final minutes = effective.inMinutes;
      final seconds = effective.inSeconds % 60;
      if (seconds == 0) {
        return '${minutes}m';
      }
      return '${minutes}m ${seconds}s';
    }
    return '${effective.inSeconds}s';
  }
}
