import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../blocs/service_details/service_details_bloc.dart';
import '../blocs/service_details/service_details_event.dart';
import '../blocs/service_details/service_details_state.dart';
import '../blocs/service_subscription/service_subscription_cubit.dart';
import '../blocs/service_subscription/service_subscription_state.dart';
import '../widgets/service_info_card.dart';
import '../widgets/service_subscription_button.dart';
import '../widgets/components_section.dart';
import '../widgets/service_details_loading.dart';
import '../widgets/service_details_error.dart';

class ServiceDetailsPage extends StatelessWidget {
  final String serviceId;

  const ServiceDetailsPage({
    super.key,
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ServiceDetailsBloc(sl())
            ..add(LoadServiceDetails(serviceId)),
        ),
        BlocProvider(
          create: (context) => ServiceSubscriptionCubit(sl()),
        ),
      ],
      child: _ServiceDetailsPageContent(serviceId: serviceId),
    );
  }
}

class _ServiceDetailsPageContent extends StatelessWidget {
  final String serviceId;

  const _ServiceDetailsPageContent({
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceSubscriptionCubit, ServiceSubscriptionState>(
      listener: (context, subscriptionState) {
        if (subscriptionState is ServiceSubscriptionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully subscribed to service!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ServiceDetailsBloc>().add(LoadServiceDetails(serviceId));
        } else if (subscriptionState is ServiceSubscriptionAwaitingAuthorization) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authorize the service in your browser to finish setup.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (subscriptionState is ServiceUnsubscribed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully unsubscribed from service'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ServiceDetailsBloc>().add(LoadServiceDetails(serviceId));
        } else if (subscriptionState is ServiceSubscriptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(subscriptionState.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, subscriptionState) {
        return BlocBuilder<ServiceDetailsBloc, ServiceDetailsState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppColors.getBackgroundColor(context),
              body: _buildBody(context, state, subscriptionState),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context,
      ServiceDetailsState state,
      ServiceSubscriptionState subscriptionState,
      ) {
    if (state is ServiceDetailsLoading) {
      return const ServiceDetailsLoadingView();
    }

    if (state is ServiceDetailsError) {
      return ServiceDetailsErrorView(
        title: 'Failed to Load Service',
        message: state.message,
        onRetry: () {
          context.read<ServiceDetailsBloc>().add(LoadServiceDetails(serviceId));
        },
      );
    }

    if (state is ServiceDetailsLoaded) {
      return CustomScrollView(
        slivers: [
          _buildAppBar(context, state, subscriptionState),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceInfoCard(service: state.service),
                const SizedBox(height: AppSpacing.md),
                ComponentsSection(
                  components: state.filteredComponents,
                  selectedKind: state.selectedComponentKind,
                  searchQuery: state.searchQuery,
                  onFilterChanged: (kind) {
                    context.read<ServiceDetailsBloc>().add(FilterComponents(kind));
                  },
                  onSearchChanged: (query) {
                    context.read<ServiceDetailsBloc>().add(SearchComponents(query));
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAppBar(
      BuildContext context,
      ServiceDetailsLoaded state,
      ServiceSubscriptionState subscriptionState,
      ) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.getSurfaceColor(context),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.arrow_back,
          color: AppColors.getTextPrimaryColor(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          state.service.displayName,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        titlePadding: const EdgeInsets.only(
          left: 56,
          bottom: 16,
          right: 16,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: ServiceSubscriptionButton(
            service: state.service,
            subscription: state.subscription,
            isLoading: subscriptionState is ServiceSubscriptionLoading ||
                subscriptionState is ServiceSubscriptionAwaitingAuthorization,
            onSubscribe: () {
              context.read<ServiceSubscriptionCubit>().subscribe(
                serviceId: state.service.id,
              );
            },
            onUnsubscribe: () {
              if (state.subscription != null) {
                context.read<ServiceSubscriptionCubit>().unsubscribe(
                  state.subscription!.id,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}