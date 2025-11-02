import 'package:area/features/areas/domain/entities/area_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_summary_repository.dart';
import '../../domain/use_cases/get_dashboard_summary.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../widgets/areas_summary_card.dart';
import '../widgets/dashboard_loading_view.dart';
import '../widgets/onboarding_checklist_card.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/services_summary_card.dart';
import '../widgets/system_status_card.dart';
import '../widgets/templates_carousel.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardCubit(GetDashboardSummary(sl<DashboardSummaryRepository>()))
            ..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const _LoadingBody();
            }

            if (state is DashboardError) {
              return _ErrorBody(
                message: state.message ?? l10n.dashboardErrorMessage,
                onRetry: () =>
                    context.read<DashboardCubit>().load(forceRefresh: true),
              );
            }

            if (state is DashboardLoaded) {
              return _LoadedBody(summary: state.summary);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _DashboardHeader(),
              ),
              const SizedBox(height: AppSpacing.lg),
              const DashboardLoadingView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.dashboardErrorTitle,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.getTextPrimaryColor(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final DashboardSummary summary;

  const _LoadedBody({required this.summary});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl + MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  OnboardingChecklistCard(
                    checklist: summary.onboardingChecklist,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  QuickActionsRow(
                    onNewArea: () => _openCreateArea(context),
                    onConnectService: () => context.go('/services'),
                    onBrowseTemplates: () => context.go('/areas'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SystemStatusCard(
                    status: summary.systemStatus,
                    onRetry: () => context.read<DashboardCubit>().refresh(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ServicesSummaryCard(
                    summary: summary.servicesSummary,
                    onTap: () => context.go('/services'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AreasSummaryCard(
                    summary: summary.areasSummary,
                    onTap: () => context.go('/areas'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RecentActivityCard(
                    activities: summary.recentActivity,
                  ),
                  if (summary.templates.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TemplatesCarousel(
                      templates: summary.templates,
                      onUseTemplate: (template) =>
                          _openTemplate(context, template),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openCreateArea(BuildContext context) async {
    final result = await context.pushNamed<bool>('area-new');
    if (result == true && context.mounted) {
      await context.read<DashboardCubit>().refresh();
    }
  }

  static Future<void> _openTemplate(
    BuildContext context,
    DashboardTemplate template,
  ) async {
    final areaTemplate = AreaTemplate(
      suggestedName: template.suggestedName,
      suggestedDescription: template.suggestedDescription,
      action: AreaTemplateStep(
        providerId: template.action.providerId,
        providerDisplayName: template.action.providerDisplayName,
        componentName: template.action.componentName,
        componentDisplayName: template.action.componentDisplayName,
        defaultParams: Map<String, dynamic>.from(template.action.defaultParams),
      ),
      reaction: AreaTemplateStep(
        providerId: template.reaction.providerId,
        providerDisplayName: template.reaction.providerDisplayName,
        componentName: template.reaction.componentName,
        componentDisplayName: template.reaction.componentDisplayName,
        defaultParams: Map<String, dynamic>.from(
          template.reaction.defaultParams,
        ),
      ),
    );

    final result = await context.pushNamed<bool>(
      'area-new',
      extra: areaTemplate,
    );
    if (result == true && context.mounted) {
      await context.read<DashboardCubit>().refresh();
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardHeaderTitle,
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.dashboardHeaderSubtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}
