import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../services/domain/repositories/services_repository.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth_event.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/subscribed_services_list.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        authRepository: sl<AuthRepository>(),
        servicesRepository: sl<ServicesRepository>(),
      )..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.getSurfaceColor(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return Center(
              child: Semantics(
                label: 'Loading profile',
                child: const CircularProgressIndicator(),
              ),
            );
          }
          if (state is ProfileError) {
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
          if (state is ProfileLoaded) {
            final user = state.user;
            final displayName = state.displayName;
            final services = state.services;
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
                final horizontalPadding = isWide ? 48.0 : (isTablet ? 24.0 : 16.0);
                const maxContentWidth = 1100.0;
                return RefreshIndicator(
                  onRefresh: () => context.read<ProfileCubit>().loadProfile(),
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.lg,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: maxContentWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                elevation: 2,
                                shadowColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.3)
                                    : AppColors.gray300.withOpacity(0.2),
                                color: AppColors.getSurfaceColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  side: BorderSide(
                                    color: AppColors.getBorderColor(context).withOpacity(0.3),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Semantics(
                                        label: 'Profile avatar',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withOpacity(0.2),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 56,
                                            backgroundColor: AppColors.primary.withOpacity(0.1),
                                            child: Text(
                                              displayName.isNotEmpty
                                                  ? displayName[0].toUpperCase()
                                                  : user.email.isNotEmpty
                                                      ? user.email[0].toUpperCase()
                                                      : '?',
                                              style: AppTypography.displayLarge.copyWith(
                                                fontSize: 48,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          displayName,
                                          style: AppTypography.displayMedium.copyWith(
                                            color: AppColors.getTextPrimaryColor(context),
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        user.email,
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.getTextSecondaryColor(context),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                      Semantics(
                                        label: 'Edit profile button',
                                        button: true,
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: FilledButton.icon(
                                            onPressed: services.isEmpty ? null : () async {
                                              final saved = await showModalBottomSheet<bool>(
                                                context: context,
                                                isScrollControlled: true,
                                                useSafeArea: true,
                                                showDragHandle: true,
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.vertical(
                                                    top: Radius.circular(28),
                                                  ),
                                                ),
                                                builder: (_) => BlocProvider.value(
                                                  value: context.read<ProfileCubit>(),
                                                  child: EditProfileSheet(state: state),
                                                ),
                                              );
                                              if (saved == true && context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(l10n.profileUpdated),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.edit_rounded, size: 24),
                                            label: Text(
                                              l10n.edit,
                                              style: AppTypography.labelLarge.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: AppColors.white,
                                              disabledBackgroundColor:
                                                  AppColors.primary.withOpacity(0.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                header: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    'Account Information',
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: AppColors.getTextPrimaryColor(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Card(
                                elevation: 2,
                                shadowColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.3)
                                    : AppColors.gray300.withOpacity(0.2),
                                color: AppColors.getSurfaceColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: AppColors.getBorderColor(context).withOpacity(0.3),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    children: [
                                      _buildInfoRow(
                                        context,
                                        Icons.fingerprint_rounded,
                                        l10n.accountId,
                                        user.id,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildInfoRow(
                                        context,
                                        Icons.verified_rounded,
                                        l10n.status,
                                        l10n.statusActive,
                                        valueColor: AppColors.success,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildInfoRow(
                                        context,
                                        Icons.calendar_today_rounded,
                                        l10n.created,
                                        l10n.notAvailable,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildInfoRow(
                                        context,
                                        Icons.access_time_rounded,
                                        l10n.lastLogin,
                                        l10n.notAvailable,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                header: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    l10n.services,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: AppColors.getTextPrimaryColor(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (services.isEmpty)
                                Card(
                                  elevation: 2,
                                  shadowColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black.withOpacity(0.3)
                                      : AppColors.gray300.withOpacity(0.2),
                                  color: AppColors.getSurfaceColor(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: AppColors.getBorderColor(context).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.xl),
                                    child: Center(
                                      child: Text(
                                        l10n.noServicesAvailable,
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.getTextSecondaryColor(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (services.isNotEmpty)
                                SubscribedServicesList(
                                  subscribedServices: state.subscribedServices,
                                ),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                header: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    l10n.security,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: AppColors.getTextPrimaryColor(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Card(
                                elevation: 2,
                                shadowColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.3)
                                    : AppColors.gray300.withOpacity(0.2),
                                color: AppColors.getSurfaceColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: AppColors.getBorderColor(context).withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Semantics(
                                      label: '${l10n.logoutAction} button',
                                      button: true,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            context.read<AuthBloc>().add(UserLoggedOut());
                                          },
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(AppSpacing.lg),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.logout_rounded,
                                                    color: AppColors.error,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: AppSpacing.md),
                                                Expanded(
                                                  child: Text(
                                                    l10n.logoutAction,
                                                    style: AppTypography.bodyLarge.copyWith(
                                                      color: AppColors.getTextPrimaryColor(context),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  size: 16,
                                                  color: AppColors.getTextTertiaryColor(context),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Divider(
                                      height: 1,
                                      color: AppColors.getDividerColor(context).withOpacity(0.5),
                                    ),
                                    Semantics(
                                      label: '${l10n.settingsAction} button',
                                      button: true,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            context.push('/profile/settings');
                                          },
                                          borderRadius: const BorderRadius.vertical(
                                            bottom: Radius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(AppSpacing.lg),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.settings_rounded,
                                                    color: AppColors.primary,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: AppSpacing.md),
                                                Expanded(
                                                  child: Text(
                                                    l10n.settingsAction,
                                                    style: AppTypography.bodyLarge.copyWith(
                                                      color: AppColors.getTextPrimaryColor(context),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  size: 16,
                                                  color: AppColors.getTextTertiaryColor(context),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
