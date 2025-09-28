import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
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
            color: AppColors.gray200.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildSearchBar(context),
          _buildTabs(context, actions.length, reactions.length),
          _buildTabContent(context, actions, reactions),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.extension_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Available Components',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurfaceVariantColor(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getBorderColor(context).withOpacity(0.3),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
          decoration: InputDecoration(
            hintText: 'Search components...',
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

  Widget _buildTabs(BuildContext context, int actionsCount, int reactionsCount) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xl),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariantColor(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
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
        ),
        unselectedLabelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            child: Text('All (${widget.components.length})'),
          ),
          Tab(
            child: Text('Actions ($actionsCount)'),
          ),
          Tab(
            child: Text('Reactions ($reactionsCount)'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
      BuildContext context,
      List<ServiceComponent> actions,
      List<ServiceComponent> reactions,
      ) {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildComponentsList(widget.components),
          _buildComponentsList(actions),
          _buildComponentsList(reactions),
        ],
      ),
    );
  }

  Widget _buildComponentsList(List<ServiceComponent> components) {
    if (components.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.gray200.withOpacity(0.3),
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
              'No components available',
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
        return _buildComponentItem(component);
      },
    );
  }

  Widget _buildComponentItem(ServiceComponent component) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariantColor(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: component.isAction
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: component.isAction
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.success.withOpacity(0.2),
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
            ],
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
            component.description,
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