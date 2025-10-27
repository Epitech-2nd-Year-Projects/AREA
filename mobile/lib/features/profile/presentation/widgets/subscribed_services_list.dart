import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../services/domain/entities/service_with_status.dart';
import '../../../services/domain/value_objects/service_category.dart';
import '../../../services/presentation/widgets/staggered_animations.dart';

class SubscribedServicesList extends StatelessWidget {
  final List<ServiceWithStatus> subscribedServices;

  const SubscribedServicesList({
    super.key,
    required this.subscribedServices,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subscribedServices.isEmpty)
          FadeInAnimation(
            duration: const Duration(milliseconds: 600),
            child: _EmptySubscriptions(l10n: l10n),
          )
        else
          StaggeredAnimation(
            delay: 100,
            child: Card(
              elevation: 2,
              shadowColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.gray300.withValues(alpha: 0.2),
              color: AppColors.getSurfaceColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.primary.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.extension_rounded,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.yourSubscriptions,
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.getTextPrimaryColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withValues(alpha: 0.2),
                                AppColors.success.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${subscribedServices.length}',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.getDividerColor(context)
                        .withValues(alpha: 0.3),
                  ),
                  SizedBox(
                    height: 310,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: subscribedServices.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: AppColors.getDividerColor(context)
                            .withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final service = subscribedServices[index];
                        final delay = 150 + (index * 50);
                        return FadeInAnimation(
                          duration: const Duration(milliseconds: 500),
                          child: _ServiceListItem(
                            service: service,
                            delay: delay,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  final ServiceWithStatus service;
  final int delay;

  const _ServiceListItem({
    required this.service,
    this.delay = 0,
  });

  Color _getCategoryColor(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.social:
        return AppColors.social;
      case ServiceCategory.productivity:
        return AppColors.productivity;
      case ServiceCategory.communication:
        return AppColors.communication;
      case ServiceCategory.storage:
        return AppColors.storage;
      case ServiceCategory.automation:
        return AppColors.automation;
      case ServiceCategory.other:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.social:
        return Icons.people_rounded;
      case ServiceCategory.productivity:
        return Icons.work_rounded;
      case ServiceCategory.communication:
        return Icons.mail_rounded;
      case ServiceCategory.storage:
        return Icons.cloud_rounded;
      case ServiceCategory.automation:
        return Icons.build_rounded;
      case ServiceCategory.other:
        return Icons.extension_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = service.provider.category;
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);

    return Semantics(
      label: '${service.provider.displayName} service',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/services/${service.provider.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.2),
                        categoryColor.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 24,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: service.provider.displayName,
                        child: Text(
                          service.provider.displayName,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.getTextPrimaryColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        category.displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.getTextTertiaryColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success.withValues(alpha: 0.2),
                            AppColors.success.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.getTextTertiaryColor(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySubscriptions extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptySubscriptions({
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.3)
          : AppColors.gray300.withValues(alpha: 0.2),
      color: AppColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                l10n.noSubscribedServicesYet,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start exploring and subscribing to services',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              label: '${l10n.discoverServices} button',
              button: true,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => context.push('/services'),
                  icon: const Icon(Icons.explore_rounded, size: 22),
                  label: Text(
                    l10n.discoverServices,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
