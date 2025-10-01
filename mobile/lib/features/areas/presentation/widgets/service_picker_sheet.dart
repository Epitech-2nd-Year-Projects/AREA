import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../services/domain/repositories/services_repository.dart';
import '../../../services/domain/use_cases/get_services_with_status.dart';
import '../../../services/domain/entities/service_with_status.dart';

class ServicePickResult {
  final String providerId;
  final String providerName;
  final bool isSubscribed;
  ServicePickResult({
    required this.providerId,
    required this.providerName,
    required this.isSubscribed,
  });
}

Future<ServicePickResult?> showServicePickerSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<ServicePickResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ServicePickerSheet(title: title),
  );
}

class _ServicePickerSheet extends StatefulWidget {
  final String title;
  const _ServicePickerSheet({required this.title});

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  late final GetServicesWithStatus _getServices =
      GetServicesWithStatus(sl<ServicesRepository>());

  List<ServiceWithStatus> _items = [];
  bool _loading = true;
  String _query = '';
  bool _onlySubscribed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final either = await _getServices.call(null);
    if (!mounted) return;
    either.fold(
      (_) {
        setState(() {
          _items = [];
          _loading = false;
        });
      },
      (list) {
        setState(() {
          _items = list;
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = _items.where((s) {
      final dn = (s.provider.displayName?.toLowerCase() ??
          s.provider.name.toLowerCase());
      if (_query.isNotEmpty && !dn.contains(_query)) return false;
      if (_onlySubscribed && !s.isSubscribed) return false;
      return true;
    }).toList();

    final maxH = MediaQuery.of(context).size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search services…',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Subscribed only'),
                  selected: _onlySubscribed,
                  onSelected: (v) => setState(() => _onlySubscribed = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('Subscribed'),
                SizedBox(width: 16),
                Icon(Icons.cancel_outlined, size: 16),
                SizedBox(width: 6),
                Text('Not subscribed'),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final s = filtered[i];
                    final name = s.provider.displayName?.isNotEmpty == true
                        ? s.provider.displayName!
                        : s.provider.name;
                    final icon =
                        s.isSubscribed ? Icons.check_circle : Icons.cancel_outlined;
                    final color = s.isSubscribed
                        ? Colors.green
                        : Theme.of(context).colorScheme.outline;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(name.characters.first.toUpperCase()),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        s.isSubscribed ? 'Subscribed' : 'Not subscribed',
                        style: TextStyle(color: color),
                      ),
                      trailing: Icon(icon, color: color),
                      onTap: () => Navigator.of(context).pop(ServicePickResult(
                        providerId: s.provider.id,
                        providerName: name,
                        isSubscribed: s.isSubscribed,
                      )),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}