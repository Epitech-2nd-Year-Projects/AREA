import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../services/domain/entities/service_with_status.dart';

class SubscribedServicesList extends StatelessWidget {
  final List<ServiceWithStatus> subscribedServices;

  const SubscribedServicesList({
    super.key,
    required this.subscribedServices,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      color: AppColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: subscribedServices.isEmpty
            ? _EmptySubscriptions(l10n: l10n)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.yourSubscriptions,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: Scrollbar(
                      child: ListView.separated(
                        itemCount: subscribedServices.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Theme.of(context).dividerColor),
                        itemBuilder: (context, index) {
                          final s = subscribedServices[index];
                          final provider = s.provider;

                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            leading: CircleAvatar(
                              child: Text(
                                provider.displayName.isNotEmpty
                                    ? provider.displayName[0].toUpperCase()
                                    : '-',
                              ),
                            ),
                            title: Text(provider.displayName),
                            subtitle: Text(l10n.subscribed),
                            trailing: const Icon(Icons.check_circle_outline),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptySubscriptions extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptySubscriptions({
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.yourSubscriptions,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(l10n.noSubscribedServicesYet),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.push('/services'),
                icon: const Icon(Icons.explore_outlined),
                label: Text(l10n.discoverServices),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
