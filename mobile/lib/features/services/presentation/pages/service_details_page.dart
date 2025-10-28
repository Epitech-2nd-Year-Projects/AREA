import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
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
import '../widgets/staggered_animations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<ServiceSubscriptionCubit, ServiceSubscriptionState>(
      listener: (context, subscriptionState) async {
        if (subscriptionState is ServiceSubscriptionSuccess) {
          _showSuccessSnackBar(
            l10n.successfullySubscribedToService,
          );
          if (mounted) {
            context
                .read<ServiceDetailsBloc>()
                .add(LoadServiceDetails(widget.serviceId));
          }
        } else if (
        subscriptionState is ServiceSubscriptionAwaitingAuthorization) {
          await _handleAuthorizationFlow(context, subscriptionState, l10n);
        } else if (subscriptionState is ServiceUnsubscribed) {
          _showSuccessSnackBar(
            l10n.successfullyUnsubscribedFromService,
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
              body: _buildBody(context, state, subscriptionState, l10n),
            );
          },
        );
      },
    );
  }

  Future<void> _handleAuthorizationFlow(
      BuildContext context,
      ServiceSubscriptionAwaitingAuthorization subscriptionState,
      AppLocalizations l10n,
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
          _showErrorSnackBar(l10n.couldNotLaunchAuthorizationUrl);
          if (mounted) {
            // ignore: use_build_context_synchronously
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
          // ignore: use_build_context_synchronously
          context
              .read<ServiceSubscriptionCubit>()
              .emit(ServiceSubscriptionInitial());
        }
      }
    } finally {
      _isLaunchingUrl = false;
    }
  }
  List<String> _getRequestedScopes(String serviceId) {
    if (serviceId.toLowerCase().contains('google')) {
      return [
        'https://www.googleapis.com/auth/gmail.send',
      ];
    }
    return [];
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
      AppLocalizations l10n,
      ) {
    if (state is ServiceDetailsLoading) {
      return const ServiceDetailsLoadingView();
    }

    if (state is ServiceDetailsError) {
      return ServiceDetailsErrorView(
        title: l10n.failedToLoadService,
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
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
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
                const SizedBox(height: AppSpacing.xxl),
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
      expandedHeight: 140,
      pinned: true,
      floating: false,
      backgroundColor: AppColors.getSurfaceColor(context),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimaryColor(context),
          ),
          tooltip: 'Go back',
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          state.service.displayName,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsets.only(
          left: 56,
          bottom: 16,
          right: 16,
        ),
        centerTitle: false,
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.primary.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withValues(alpha: 0.02),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.sm, bottom: AppSpacing.sm),
          child: FadeInAnimation(
            child: ServiceSubscriptionButton(
              service: state.service,
              subscription: state.subscription,
              isLoading: subscriptionState is ServiceSubscriptionLoading ||
                  subscriptionState is ServiceSubscriptionAwaitingAuthorization,
              onSubscribe: () {
                context.read<ServiceSubscriptionCubit>().subscribe(
                  serviceId: state.service.name,
                  requestedScopes: _getRequestedScopes(state.service.name),
                );
              },
              onUnsubscribe: () {
                context.read<ServiceSubscriptionCubit>().unsubscribe(
                  state.service.name,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}