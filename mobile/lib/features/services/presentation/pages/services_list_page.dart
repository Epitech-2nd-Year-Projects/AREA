import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../blocs/services_list/services_list_bloc.dart';
import '../blocs/services_list/services_list_event.dart';
import '../blocs/services_list/services_list_state.dart';
import '../widgets/services_search_bar.dart';
import '../widgets/services_filter_chips.dart';
import '../widgets/service_card.dart';
import '../widgets/services_loading_shimmer.dart';
import '../widgets/services_error_widget.dart';
import '../widgets/empty_services_state.dart';

class ServicesListPage extends StatelessWidget {
  const ServicesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ServicesListBloc(sl())..add(LoadServices()),
      child: const _ServicesListPageContent(),
    );
  }
}

class _ServicesListPageContent extends StatelessWidget {
  const _ServicesListPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: BlocConsumer<ServicesListBloc, ServicesListState>(
        listener: (context, state) {
          if (state is ServicesListError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ServicesListBloc>().add(RefreshServices());
            },
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSearchAndFilters(context, state),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                _buildServicesList(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect Your Services',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Subscribe to services to create powerful automations',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, ServicesListState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServicesSearchBar(
            onSearch: (query) {
              context.read<ServicesListBloc>().add(SearchServices(query));
            },
            initialValue: state is ServicesListLoaded ? state.searchQuery : '',
            onClear: () {
              context.read<ServicesListBloc>().add(ClearFilters());
            },
            hasActiveFilters: state is ServicesListLoaded &&
                (state.selectedCategory != null || state.searchQuery.isNotEmpty),
          ),
          const SizedBox(height: AppSpacing.md),
          ServicesFilterChips(
            selectedCategory: state is ServicesListLoaded ? state.selectedCategory : null,
            onCategorySelected: (category) {
              context.read<ServicesListBloc>().add(FilterByCategory(category));
            },
            hasActiveFilters: state is ServicesListLoaded &&
                (state.selectedCategory != null || state.searchQuery.isNotEmpty),
            onClearFilters: () {
              context.read<ServicesListBloc>().add(ClearFilters());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, ServicesListState state) {
    if (state is ServicesListLoading) {
      return const SliverToBoxAdapter(
        child: ServicesLoadingShimmer(),
      );
    }

    if (state is ServicesListError) {
      return SliverToBoxAdapter(
        child: ServicesErrorWidget(
          title: 'Failed to Load Services',
          message: state.message,
          onRetry: () {
            context.read<ServicesListBloc>().add(LoadServices());
          },
        ),
      );
    }

    if (state is ServicesListLoaded) {
      if (state.filteredServices.isEmpty) {
        return SliverToBoxAdapter(
          child: EmptyServicesState(
            hasFilters: state.selectedCategory != null || state.searchQuery.isNotEmpty,
            onClearFilters: () {
              context.read<ServicesListBloc>().add(ClearFilters());
            },
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.crossAxisExtent > 600 ? 3 : 2;
            const aspectRatio = 0.8;

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final service = state.filteredServices[index];
                  return ServiceCard(
                    service: service,
                    onTap: () {
                      context.push('/services/${service.provider.id}');
                    },
                  );
                },
                childCount: state.filteredServices.length,
              ),
            );
          },
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}