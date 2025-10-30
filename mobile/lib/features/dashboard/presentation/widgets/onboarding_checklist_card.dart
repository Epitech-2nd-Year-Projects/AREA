import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import 'dashboard_card.dart';

class OnboardingChecklistCard extends StatelessWidget {
  final DashboardOnboardingChecklist checklist;

  const OnboardingChecklistCard({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AppColors.getTextPrimaryColor(context);
    final secondaryColor = AppColors.getTextSecondaryColor(context);
    final steps = checklist.steps;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardChecklistTitle,
            style: AppTypography.headlineMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.dashboardChecklistSubtitle,
            style: AppTypography.bodyMedium.copyWith(color: secondaryColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                _ChecklistRow(
                  step: steps[i],
                  title: _titleForStep(l10n, steps[i]),
                  description: _descriptionForStep(steps[i]),
                  isLast: i == steps.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _titleForStep(AppLocalizations l10n, DashboardChecklistStep step) {
    switch (step.id) {
      case 'connect-service':
        return l10n.dashboardChecklistStepConnectService;
      case 'create-area':
        return l10n.dashboardChecklistStepCreateArea;
      case 'run-test':
        return l10n.dashboardChecklistStepRunTest;
      default:
        return step.title;
    }
  }

  String? _descriptionForStep(DashboardChecklistStep step) {
    return step.description;
  }
}

class _ChecklistRow extends StatelessWidget {
  final DashboardChecklistStep step;
  final bool isLast;
  final String title;
  final String? description;

  const _ChecklistRow({
    required this.step,
    required this.title,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.isCompleted;
    final backgroundColor = isCompleted
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.getDividerColor(context).withValues(alpha: 0.4);
    final iconColor = isCompleted
        ? AppColors.primary
        : AppColors.getTextSecondaryColor(context);
    final textColor = AppColors.getTextPrimaryColor(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.radio_button_unchecked,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
