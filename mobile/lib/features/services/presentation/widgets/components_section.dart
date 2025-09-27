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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Available Components',
        style: AppTypography.headlineMedium.copyWith(
          color: AppColors.getTextPrimaryColor(context),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search components...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              widget.onSearchChanged('');
            },
            icon: const Icon(Icons.clear),
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: widget.onSearchChanged,
      ),
    );
  }

  Widget _buildTabs(BuildContext context, int actionsCount, int reactionsCount) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.getTextSecondaryColor(context),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'All (${widget.components.length})'),
          Tab(text: 'Actions ($actionsCount)'),
          Tab(text: 'Reactions ($reactionsCount)'),
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
      height: 300,
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
      return const Center(
        child: Text('No components available'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: components.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final component = components[index];
        return _buildComponentItem(component);
      },
    );
  }

  Widget _buildComponentItem(ServiceComponent component) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: component.isAction
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  component.kind.displayName,
                  style: AppTypography.labelMedium.copyWith(
                    color: component.isAction ? AppColors.primary : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            component.displayName,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.getTextPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            component.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}