import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/area_status.dart';
import '../../domain/entities/area_component_binding.dart';

class AreaCard extends StatelessWidget {
  final Area area;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AreaCard({
    super.key,
    required this.area,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBadge = _buildStatusBadge(context, area.status, l10n);
    final actionSummary = _formatComponent(area.action);
    final reactionSummaries = area.reactions.map(_formatComponent).toList();
    final reactionRowWidgets = reactionSummaries.asMap().entries.map((entry) {
      final label = entry.key == 0
          ? l10n.reaction
          : l10n.reactionNumber(entry.key + 1);
      return _buildSummaryRow(
        context,
        label,
        entry.value,
        Icons.settings_suggest,
      );
    }).toList();
    final bool useScrollableReactions = reactionRowWidgets.length > 3;
    final double estimatedRowHeight = 56.0;
    final double reactionsMaxHeight = 220.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.gray300.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        area.name,
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (area.description != null &&
                        area.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          area.description!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.getTextSecondaryColor(context),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              statusBadge,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceVariantColor(
                context,
              ).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.getBorderColor(context).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryRow(
                  context,
                  l10n.action,
                  actionSummary,
                  Icons.flash_on,
                ),
                if (reactionRowWidgets.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Divider(
                      color: AppColors.getDividerColor(
                        context,
                      ).withValues(alpha: 0.5),
                      height: 1,
                    ),
                  ),
                  useScrollableReactions
                      ? SizedBox(
                          height: math.min(
                            reactionsMaxHeight,
                            reactionRowWidgets.length * estimatedRowHeight,
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              physics: const ClampingScrollPhysics(),
                              shrinkWrap: true,
                              itemBuilder: (context, index) =>
                                  reactionRowWidgets[index],
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemCount: reactionRowWidgets.length,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (
                              var i = 0;
                              i < reactionRowWidgets.length;
                              i++
                            ) ...[
                              if (i != 0) const SizedBox(height: AppSpacing.sm),
                              reactionRowWidgets[i],
                            ],
                          ],
                        ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Semantics(
                label: '${l10n.toolTipEdit} ${area.name}',
                button: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.toolTipEdit,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                label: '${l10n.toolTipDelete} ${area.name}',
                button: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.toolTipDelete,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    AreaStatus status,
    AppLocalizations l10n,
  ) {
    final color = switch (status) {
      AreaStatus.enabled => AppColors.success,
      AreaStatus.disabled => AppColors.gray600,
      AreaStatus.archived => AppColors.warning,
    };
    final label = switch (status) {
      AreaStatus.enabled => l10n.enabled,
      AreaStatus.disabled => l10n.disabled,
      AreaStatus.archived => l10n.archived,
    };
    final icon = switch (status) {
      AreaStatus.enabled => Icons.check_circle_rounded,
      AreaStatus.disabled => Icons.pause_circle_outline_rounded,
      AreaStatus.archived => Icons.archive_outlined,
    };

    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatComponent(AreaComponentBinding binding) {
    final provider = binding.component.provider.displayName;
    final componentName = binding.name?.isNotEmpty == true
        ? binding.name!
        : binding.component.displayName;
    return '$provider - $componentName';
  }
}
