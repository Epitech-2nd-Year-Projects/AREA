import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/service_component.dart';
import '../../domain/value_objects/component_kind.dart';
import 'staggered_animations.dart';

class ComponentsSection extends StatefulWidget {
  final List<ServiceComponent> components;
  final ComponentKind? selectedKind;
  final String searchQuery;
  final Function(ComponentKind?) onFilterChanged;
  final Function(String) onSearchChanged;

  const ComponentsSection({
    super.key,
    required this.components,
    this.selectedKind,
    required this.searchQuery,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  @override
  State<ComponentsSection> createState() => _ComponentsSectionState();
}

class _ComponentsSectionState extends State<ComponentsSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = widget.components.where((c) => c.isAction).toList();
    final reactions = widget.components.where((c) => c.isReaction).toList();

    return StaggeredAnimation(
      delay: 200,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.getBorderColor(context).withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.gray200.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, l10n),
            _buildSearchBar(context, l10n),
            _buildTabs(context, actions.length, reactions.length, l10n),
            SizedBox(
              height: 400,
              child: _buildTabContent(context, actions, reactions, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVeryCompact = constraints.maxWidth < 280;

          if (isVeryCompact) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.extension_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.availableComponents,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.extension_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.availableComponents,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: StaggeredAnimation(
        delay: 150,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.getSurfaceVariantColor(
                  context,
                ).withValues(alpha: 0.4),
                AppColors.getSurfaceVariantColor(
                  context,
                ).withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.getTextPrimaryColor(context),
            ),
            decoration: InputDecoration(
              hintText: l10n.searchComponents,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.getTextTertiaryColor(context),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.getTextSecondaryColor(context),
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                      icon: Icon(
                        Icons.clear_rounded,
                        color: AppColors.getTextSecondaryColor(context),
                        size: 20,
                      ),
                      tooltip: 'Clear search',
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(
    BuildContext context,
    int actionsCount,
    int reactionsCount,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xl),
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.5),
            AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = constraints.maxWidth < 280 ? 11.0 : null;

          return TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            indicatorPadding: const EdgeInsets.all(3),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.getTextSecondaryColor(context),
            labelStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
            unselectedLabelStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: '${l10n.allTab} (${widget.components.length})'),
              Tab(text: '${l10n.actionsTab} ($actionsCount)'),
              Tab(text: '${l10n.reactionsTab} ($reactionsCount)'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    List<ServiceComponent> actions,
    List<ServiceComponent> reactions,
    AppLocalizations l10n,
  ) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildComponentsList(widget.components, l10n),
        _buildComponentsList(actions, l10n),
        _buildComponentsList(reactions, l10n),
      ],
    );
  }

  Widget _buildComponentsList(
    List<ServiceComponent> components,
    AppLocalizations l10n,
  ) {
    if (components.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gray200.withValues(alpha: 0.4),
                    AppColors.gray200.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray200.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.inbox_rounded,
                color: AppColors.getTextTertiaryColor(context),
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noComponentsAvailable,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl * 3,
      ),
      itemCount: components.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final component = components[index];
        return StaggeredAnimation(
          delay: 100 + (index * 50),
          duration: const Duration(milliseconds: 400),
          child: _buildComponentItem(component, l10n),
        );
      },
    );
  }

  Widget _buildComponentItem(
    ServiceComponent component,
    AppLocalizations l10n,
  ) {
    final componentColor = component.isAction
        ? AppColors.primary
        : AppColors.success;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.pushNamed('area-new', extra: component);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.getSurfaceVariantColor(
                  context,
                ).withValues(alpha: 0.4),
                AppColors.getSurfaceVariantColor(
                  context,
                ).withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: componentColor.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      componentColor.withValues(alpha: 0.15),
                      componentColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: componentColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: componentColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      component.isAction
                          ? Icons.play_arrow_rounded
                          : Icons.bolt_rounded,
                      color: componentColor,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      component.kind.displayName,
                      style: AppTypography.labelMedium.copyWith(
                        color: componentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                component.displayName,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                component.description ?? l10n.noDescriptionProvided,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                  height: 1.5,
                  fontSize: 13.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
