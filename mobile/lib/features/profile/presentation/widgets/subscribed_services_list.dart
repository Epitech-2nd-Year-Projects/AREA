import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/domain/entities/service_with_status.dart';

class SubscribedServicesList extends StatelessWidget {
  final List<ServiceWithStatus> subscribedServices;

  const SubscribedServicesList({
    super.key,
    required this.subscribedServices,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: subscribedServices.isEmpty
            ? const _EmptySubscriptions()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your subscriptions',
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
                            subtitle: const Text('Subscribed'),
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
  const _EmptySubscriptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your subscriptions',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('No subscribed services yet.'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/services'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Discover services'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
