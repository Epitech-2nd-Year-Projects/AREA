import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../domain/entities/area.dart';

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
    final bool isActive = area.isActive;
    final Widget statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success : AppColors.gray600,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.remove_circle,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
              const SizedBox(width: AppSpacing.md),
              statusBadge,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _buildActionReactionText(),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildActionReactionText() {
    const actionLabels = {
      'issue_created': 'Issue created (GitHub)',
      'mail_with_attachment': 'Email with attachment (Gmail)',
    };
    const reactionLabels = {
      'send_teams_message': 'Send Teams message',
      'save_to_onedrive': 'Save to OneDrive',
    };
    final aLabel = actionLabels[area.actionName] ?? area.actionName;
    final rLabel = reactionLabels[area.reactionName] ?? area.reactionName;
    return '$aLabel → $rLabel';
  }
}
