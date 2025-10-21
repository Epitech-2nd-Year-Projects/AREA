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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                    Text(
                      area.name,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (area.description != null && area.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          area.description!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              statusBadge,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow(context, l10n.action, actionSummary),
          const SizedBox(height: AppSpacing.xs),
          ...reactionSummaries.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(top: entry.key == 0 ? 0 : AppSpacing.xs),
                child: _buildSummaryRow(context, entry.key == 0 ? l10n.reaction : 'Reaction ${entry.key + 1}', entry.value),
              )),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: l10n.toolTipEdit,
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                tooltip: l10n.toolTipDelete,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AreaStatus status, AppLocalizations l10n) {
    final isActive = status == AreaStatus.enabled;
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle_outline,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextPrimaryColor(context),
            ),
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
