import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
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
      appBar: AppBar(title: Text(l10n.profile)),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileError) {
            return Center(
              child: Text(state.message, style: const TextStyle(color: Colors.red)),
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
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: maxContentWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                elevation: 0,
                                color: AppColors.getSurfaceColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.getBorderColor(context)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        child: Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : user.email.isNotEmpty
                                                  ? user.email[0].toUpperCase()
                                                  : '?',
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        displayName,
                                        style: Theme.of(context).textTheme.headlineSmall,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: services.isEmpty ? null : () async {
                                          final saved = await showModalBottomSheet<bool>(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            showDragHandle: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                            ),
                                            builder: (_) => BlocProvider.value(
                                              value: context.read<ProfileCubit>(),
                                              child: EditProfileSheet(state: state),
                                            ),
                                          );
                                          if (saved == true && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(l10n.profileUpdated,)),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: Text(l10n.edit),
                                        style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                elevation: 0,
                                color: AppColors.getSurfaceColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.getBorderColor(context)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${l10n.accountId}: ${user.id}'),
                                      const SizedBox(height: 4),
                                      Text('${l10n.status}: ${l10n.statusActive}'),
                                      const SizedBox(height: 4),
                                      Text('${l10n.created}: ${l10n.notAvailable}'),
                                      const SizedBox(height: 4),
                                      Text('${l10n.lastLogin}: ${l10n.notAvailable}'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.services,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (services.isEmpty)
                                Text(l10n.noServicesAvailable),
                              if (services.isNotEmpty)
                                SubscribedServicesList(subscribedServices: state.subscribedServices),
                              const SizedBox(height: 16),
                              Text(
                                l10n.security,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 0,
                                color: AppColors.getSurfaceColor(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.getBorderColor(context)),
                                ),
                                child: Column(
                                  children: ListTile.divideTiles(
                                    context: context,
                                    tiles: [
                                      ListTile(
                                        leading: const Icon(Icons.logout),
                                        title: Text(l10n.logoutAction),
                                        onTap: () {
                                          context.read<AuthBloc>().add(UserLoggedOut());
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete_forever),
                                        title: Text(l10n.deleteAccount),
                                        subtitle: Text(l10n.notAvailable),
                                        enabled: false,
                                        onTap: null,
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.settings),
                                        title: Text(l10n.settingsAction),
                                        onTap: () {
                                          context.push('/profile/settings');
                                        },
                                      ),
                                    ],
                                  ).toList(),
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
}
