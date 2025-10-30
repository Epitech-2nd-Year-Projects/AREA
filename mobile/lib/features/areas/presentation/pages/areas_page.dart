import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/area_repository.dart';
import '../cubits/areas_cubit.dart';
import '../cubits/areas_state.dart';
import '../../domain/entities/area.dart';
import '../widgets/area_card.dart';

class AreasPage extends StatelessWidget {
  const AreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AreasCubit>(
      create: (_) => AreasCubit(sl<AreaRepository>())..fetchAreas(),
      child: const _AreasScreen(),
    );
  }
}

class _AreasScreen extends StatelessWidget {
  const _AreasScreen();

  Future<void> _openCreate(BuildContext context) async {
    final bool? refreshed = await context.pushNamed('area-new');
    if (refreshed == true && context.mounted) {
      context.read<AreasCubit>().fetchAreas();
    }
  }

  Future<void> _openEdit(BuildContext context, Area area) async {
    final bool? refreshed = await context.pushNamed('area-edit', extra: area);
    if (refreshed == true && context.mounted) {
      context.read<AreasCubit>().fetchAreas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          l10n.myAreas,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.getSurfaceColor(context),
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCreate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.newAreaButton,
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AreasCubit, AreasState>(
        builder: (context, state) {
          if (state is AreasLoading) {
            return Center(
              child: Semantics(
                label: l10n.myAreas,
                child: const CircularProgressIndicator(),
              ),
            );
          }
          if (state is AreasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                      semanticLabel: 'Error',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      state.message,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is AreasLoaded) {
            final areas = state.areas;

            if (areas.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => context.read<AreasCubit>().fetchAreas(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: AppColors.getSurfaceVariantColor(
                                    context,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 64,
                                  color: AppColors.getTextTertiaryColor(
                                    context,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                l10n.noAutomationConfigured,
                                style: AppTypography.headlineMedium.copyWith(
                                  color: AppColors.getTextPrimaryColor(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Create your first automation to get started',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<AreasCubit>().fetchAreas(),
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  bottom: 150,
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                ),
                itemCount: areas.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final area = areas[index];
                  return Semantics(
                    label: '${area.name} automation',
                    button: true,
                    child: AreaCard(
                      area: area,
                      onEdit: () => _openEdit(context, area),
                      onDelete: () async {
                        await context.read<AreasCubit>().removeArea(area.id);
                      },
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
