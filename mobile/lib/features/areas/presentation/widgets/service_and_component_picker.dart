import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/domain/entities/service_component.dart';
import '../../../services/domain/value_objects/component_kind.dart';
import '../cubits/area_form_cubit.dart';

enum ServiceComponentKind { action, reaction }

class ServiceAndComponentPicker extends StatefulWidget {
  final String title;

  final String? providerId;
  final String? providerLabel;
  final bool? isSubscribed;

  final String? selectedComponentId;
  final ServiceComponentKind kind;

  final VoidCallback onSelectService;
  final ValueChanged<String?> onComponentChanged;
  final ValueChanged<ServiceComponent?> onComponentSelected;

  const ServiceAndComponentPicker({
    super.key,
    required this.title,
    required this.providerId,
    required this.providerLabel,
    required this.isSubscribed,
    required this.selectedComponentId,
    required this.kind,
    required this.onSelectService,
    required this.onComponentChanged,
    required this.onComponentSelected,
  });

  @override
  State<ServiceAndComponentPicker> createState() => _ServiceAndComponentPickerState();
}

class _ServiceAndComponentPickerState extends State<ServiceAndComponentPicker> {
  bool _loading = false;
  List<ServiceComponent> _components = [];

  @override
  void initState() {
    super.initState();
    if (widget.providerId != null) {
      _loadComponents(widget.providerId!);
    }
  }

  @override
  void didUpdateWidget(covariant ServiceAndComponentPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.providerId != widget.providerId) {
      _components = [];
      _loading = widget.providerId != null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComponentChanged(null);
        widget.onComponentSelected(null);

        if (widget.providerId != null && mounted) {
          _loadComponents(widget.providerId!);
        } else {
          if (mounted) setState(() {});
        }
      });
    }
  }

  Future<void> _loadComponents(String providerId) async {
    final cubit = context.read<AreaFormCubit>();

    setState(() {
      _loading = true;
      _components = [];
    });

    final kind = widget.kind == ServiceComponentKind.action
        ? ComponentKind.action
        : ComponentKind.reaction;

    final list = await cubit.getComponentsFor(providerId, kind: kind);
    if (!mounted) return;

    _components = list;
    _loading = false;

    if (widget.selectedComponentId != null &&
        !_components.any((e) => e.id == widget.selectedComponentId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onComponentChanged(null);
          widget.onComponentSelected(null);
        }
      });
    } else if (widget.selectedComponentId != null) {
      ServiceComponent? selected;
      try {
        selected = _components.firstWhere((c) => c.id == widget.selectedComponentId);
      } catch (_) {
        selected = null;
      }
      if (selected != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComponentSelected(selected);
        });
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final badge = _buildBadge(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                badge,
              ],
            ),
            const SizedBox(height: 12),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.15),
              leading: const Icon(Icons.apps),
              title: Text(
                widget.providerLabel ?? 'Select ${widget.title.toLowerCase()} service',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.edit),
              onTap: widget.onSelectService,
            ),

            const SizedBox(height: 12),

            if (widget.providerId != null) ...[
              if (_loading) const LinearProgressIndicator(),
              if (!_loading)
                _components.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No ${widget.title.toLowerCase()} components for this service',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: (widget.selectedComponentId != null &&
                                _components.any((e) => e.id == widget.selectedComponentId))
                            ? widget.selectedComponentId
                            : null,
                        hint: Text('Choose a ${widget.title.toLowerCase()} component'),
                        items: _components
                            .map((component) => DropdownMenuItem<String>(
                                  value: component.id,
                                  child: Text(component.displayName, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (value) {
                          widget.onComponentChanged(value);
                          if (value == null) {
                            widget.onComponentSelected(null);
                          } else {
                            final component = _components.firstWhere(
                              (c) => c.id == value,
                              orElse: () => _components.first,
                            );
                            widget.onComponentSelected(component);
                          }
                        },
                        validator: (v) => v == null ? 'Select a component' : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    if (widget.providerId == null) return const SizedBox.shrink();

    final cubit = context.read<AreaFormCubit>();
    final cached = cubit.isServiceSubscribedSync(widget.providerId!);

    if (cached == null) {
      cubit.checkSubscriptionActive(widget.providerId!);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 6),
          Text('Checking…'),
        ],
      );
    }

    final isSub = widget.isSubscribed ?? cached;
    final color = isSub ? Colors.green : Theme.of(context).colorScheme.error;
    final icon = isSub ? Icons.check_circle : Icons.cancel_outlined;
    final text = isSub ? 'Subscribed' : 'Not subscribed';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}


