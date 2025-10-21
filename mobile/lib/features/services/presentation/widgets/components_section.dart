import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/service_component.dart';
import '../../domain/value_objects/component_kind.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
          ),
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
    );
  }

  Widget _buildTabs(BuildContext context, int actionsCount, int reactionsCount, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xl),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = constraints.maxWidth < 280 ? 11.0 : null;

          return TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorPadding: const EdgeInsets.all(2),
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
              Tab(text: '${l10n.allTab}(${widget.components.length})'),
              Tab(text: '${l10n.actionsTab} ($actionsCount)'),
              Tab(text: '${l10n.reactionsTab}($reactionsCount)'),
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
      AppLocalizations l10n
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

  Widget _buildComponentsList(List<ServiceComponent> components, AppLocalizations l10n) {
    if (components.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.gray200.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                color: AppColors.getTextTertiaryColor(context),
                size: 32,
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
        AppSpacing.xl,
      ),
      itemCount: components.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final component = components[index];
        return _buildComponentItem(component, l10n);
      },
    );
  }

  Widget _buildComponentItem(ServiceComponent component, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
        ),
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
              color: component.isAction
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: component.isAction
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.success.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  component.isAction ? Icons.play_arrow_rounded : Icons.bolt_rounded,
                  color: component.isAction ? AppColors.primary : AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  component.kind.displayName,
                  style: AppTypography.labelMedium.copyWith(
                    color: component.isAction ? AppColors.primary : AppColors.success,
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
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            component.description ?? l10n.noDescriptionProvided,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
