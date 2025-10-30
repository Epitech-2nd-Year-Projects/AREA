import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';

class TemplatesCarousel extends StatelessWidget {
  final List<DashboardTemplate> templates;
  final ValueChanged<DashboardTemplate> onUseTemplate;

  const TemplatesCarousel({
    super.key,
    required this.templates,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (templates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardTemplatesTitle,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 204,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateCard(
                template: template,
                onUseTemplate: () => onUseTemplate(template),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DashboardTemplate template;
  final VoidCallback onUseTemplate;

  const _TemplateCard({required this.template, required this.onUseTemplate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = AppColors.getSurfaceColor(context);
    final surfaceVariantColor = AppColors.getSurfaceVariantColor(context);
    final primaryColor = AppColors.primary;
    final Color gradientStart = Color.alphaBlend(
      primaryColor.withValues(alpha: isDark ? 0.35 : 0.18),
      surfaceColor,
    );
    final Color gradientEnd = Color.alphaBlend(
      primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
      surfaceVariantColor,
    );
    final Color borderColor = AppColors.getBorderColor(
      context,
    ).withValues(alpha: isDark ? 0.45 : 0.35);
    final Color labelColor = AppColors.getTextSecondaryColor(
      context,
    ).withValues(alpha: 0.92);
    final Color titleColor = AppColors.getTextPrimaryColor(context);
    final Color descriptionColor = AppColors.getTextSecondaryColor(
      context,
    ).withValues(alpha: 0.94);
    final String serviceLabel = template.secondaryService != null
        ? '${template.primaryService} → ${template.secondaryService}'
        : template.primaryService;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serviceLabel,
              style: AppTypography.labelLarge.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      template.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: descriptionColor,
                      ),
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUseTemplate,
                child: Text(l10n.dashboardTemplatesUseTemplate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
