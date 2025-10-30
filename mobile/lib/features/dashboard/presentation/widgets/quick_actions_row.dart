import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import 'dashboard_card.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onNewArea;
  final VoidCallback onConnectService;
  final VoidCallback onBrowseTemplates;

  const QuickActionsRow({
    super.key,
    required this.onNewArea,
    required this.onConnectService,
    required this.onBrowseTemplates,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = AppColors.getTextPrimaryColor(context);

    return DashboardCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.lg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            (
              icon: Icons.auto_awesome,
              label: l10n.dashboardQuickActionsNewArea,
              handler: onNewArea,
            ),
            (
              icon: Icons.link,
              label: l10n.dashboardQuickActionsConnectService,
              handler: onConnectService,
            ),
            (
              icon: Icons.explore,
              label: l10n.dashboardQuickActionsBrowseTemplates,
              handler: onBrowseTemplates,
            ),
          ];

          final isWide = constraints.maxWidth >= 520;
          final isMedium = constraints.maxWidth >= 360;
          final buttonSpacing = isWide ? AppSpacing.md : AppSpacing.sm;

          Widget buildButtons() {
            if (isWide) {
              return Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    Expanded(
                      child: _QuickActionButton(
                        icon: actions[i].icon,
                        label: actions[i].label,
                        onPressed: actions[i].handler,
                        dense: false,
                      ),
                    ),
                    if (i != actions.length - 1) SizedBox(width: buttonSpacing),
                  ],
                ],
              );
            }

            return Wrap(
              spacing: buttonSpacing,
              runSpacing: buttonSpacing,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: isMedium
                          ? (constraints.maxWidth - buttonSpacing) / 2
                          : double.infinity,
                      child: _QuickActionButton(
                        icon: action.icon,
                        label: action.label,
                        onPressed: action.handler,
                        dense: !isMedium,
                      ),
                    ),
                  )
                  .toList(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardQuickActionsTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              buildButtons(),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool dense;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final minHeight = dense ? 44.0 : 52.0;

    return Semantics(
      button: true,
      label: label,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(double.infinity, minHeight),
          padding: EdgeInsets.symmetric(
            vertical: dense ? AppSpacing.xs : AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        icon: Icon(icon, size: 20),
        label: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? AppSpacing.xs : AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
