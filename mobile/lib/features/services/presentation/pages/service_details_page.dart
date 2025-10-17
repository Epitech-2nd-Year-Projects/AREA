import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injector.dart';
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

class _ServiceDetailsPageContent extends StatefulWidget {
  final String serviceId;

  const _ServiceDetailsPageContent({
    required this.serviceId,
  });

  @override
  State<_ServiceDetailsPageContent> createState() =>
      _ServiceDetailsPageContentState();
}

class _ServiceDetailsPageContentState extends State<_ServiceDetailsPageContent> {
  bool _isLaunchingUrl = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceSubscriptionCubit, ServiceSubscriptionState>(
      listener: (context, subscriptionState) async {
        if (subscriptionState is ServiceSubscriptionSuccess) {
          _showSuccessSnackBar(
            'Successfully subscribed to service!',
          );
          if (mounted) {
            context
                .read<ServiceDetailsBloc>()
                .add(LoadServiceDetails(widget.serviceId));
          }
        } else if (
        subscriptionState is ServiceSubscriptionAwaitingAuthorization) {
          await _handleAuthorizationFlow(context, subscriptionState);
        } else if (subscriptionState is ServiceUnsubscribed) {
          _showSuccessSnackBar(
            'Successfully unsubscribed from service',
          );
          if (mounted) {
            context
                .read<ServiceDetailsBloc>()
                .add(LoadServiceDetails(widget.serviceId));
          }
        } else if (subscriptionState is ServiceSubscriptionError) {
          _showErrorSnackBar(subscriptionState.message);
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

  Future<void> _handleAuthorizationFlow(
      BuildContext context,
      ServiceSubscriptionAwaitingAuthorization subscriptionState,
      ) async {
    if (_isLaunchingUrl) {
      debugPrint('⏳ URL launch already in progress, ignoring...');
      return;
    }

    try {
      _isLaunchingUrl = true;

      final currentPath = '/services/${widget.serviceId}';
      final authUrl = subscriptionState.authorizationUrl;

      debugPrint('🔗 Authorization URL: $authUrl');

      final uri = Uri.parse(authUrl);
      final modifiedUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'returnTo': currentPath,
        },
      );

      debugPrint('🚀 Launching authorization URL...');
      debugPrint('   Full URL: ${modifiedUri.toString()}');

      final launched = await launchUrl(
        modifiedUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('❌ Failed to launch URL');
        if (mounted) {
          _showErrorSnackBar('Could not launch authorization URL');
          if (mounted) {
            context
                .read<ServiceSubscriptionCubit>()
                .emit(ServiceSubscriptionInitial());
          }
        }
      } else {
        debugPrint('✅ URL launched successfully');
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      if (mounted) {
        _showErrorSnackBar('Error launching authorization: $e');
        if (mounted) {
          context
              .read<ServiceSubscriptionCubit>()
              .emit(ServiceSubscriptionInitial());
        }
      }
    } finally {
      _isLaunchingUrl = false;
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
          context
              .read<ServiceDetailsBloc>()
              .add(LoadServiceDetails(widget.serviceId));
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
                    context
                        .read<ServiceDetailsBloc>()
                        .add(FilterComponents(kind));
                  },
                  onSearchChanged: (query) {
                    context
                        .read<ServiceDetailsBloc>()
                        .add(SearchComponents(query));
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