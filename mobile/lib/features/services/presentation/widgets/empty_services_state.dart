import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

class EmptyServicesState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback? onClearFilters;

  const EmptyServicesState({
    super.key,
    required this.hasFilters,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.apps_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              hasFilters ? l10n.noServicesFound : l10n.noServicesAvailable,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilters
                  ? l10n.tryAdjustingSearchOrFilters
                  : l10n.servicesWillAppearHereOnceAvailable,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters && onClearFilters != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear),
                label: Text(l10n.clearFilters),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
