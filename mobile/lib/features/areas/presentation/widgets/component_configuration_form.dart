import 'package:flutter/material.dart';

import '../../../services/domain/entities/component_parameter.dart';
import '../../../services/domain/entities/service_component.dart';

class ComponentConfigurationForm extends StatefulWidget {
  final String title;
  final ServiceComponent? component;
  final String? initialName;
  final Map<String, dynamic> initialValues;
  final bool enabled;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<Map<String, dynamic>> onParametersChanged;

  const ComponentConfigurationForm({
    super.key,
    required this.title,
    required this.component,
    required this.initialName,
    required this.initialValues,
    required this.enabled,
    required this.onNameChanged,
    required this.onParametersChanged,
  });

  @override
  State<ComponentConfigurationForm> createState() => _ComponentConfigurationFormState();
}

class _ComponentConfigurationFormState extends State<ComponentConfigurationForm> {
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, dynamic> _values = {};
  TextEditingController? _nameController;
  String? _componentId;

  @override
  void initState() {
    super.initState();
    _syncWithComponent(notify: true);
  }

  @override
  void didUpdateWidget(ComponentConfigurationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newId = widget.component?.id;
    final oldId = oldWidget.component?.id;
    if (newId != oldId || oldWidget.initialValues != widget.initialValues) {
      _syncWithComponent(notify: true);
    } else if (widget.enabled != oldWidget.enabled) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    _nameController?.dispose();
    _nameController = null;
  }

  void _syncWithComponent({required bool notify}) {
    _disposeControllers();
    _values.clear();
    _componentId = widget.component?.id;

    final component = widget.component;
    if (component == null) {
      widget.onNameChanged(null);
      widget.onParametersChanged(const {});
      setState(() {});
      return;
    }

    _nameController = TextEditingController(
      text: widget.initialName ?? component.displayName,
    );
    _nameController!.addListener(() {
      widget.onNameChanged(_normalizeName(_nameController!.text));
    });
    widget.onNameChanged(_normalizeName(_nameController!.text));

    final incoming = Map<String, dynamic>.from(widget.initialValues);

    for (final param in component.parameters) {
      dynamic value = incoming[param.key];

      if (value == null) {
        if (param.extras.containsKey('default')) {
          value = param.extras['default'];
        } else if (param.type == 'boolean') {
          value = false;
        } else if (param.hasOptions) {
          value = param.options.first.value;
        } else {
          value = '';
        }
      }

      if (param.type == 'boolean' && value is! bool) {
        value = value == true || value == 'true';
      }

      if (param.hasOptions) {
        final options = param.options.map((o) => o.value).toSet();
        if (!options.contains(value)) {
          value = param.options.first.value;
        }
      }

      _values[param.key] = value;

      if (param.type == 'boolean' || param.hasOptions) {
        continue;
      }

      final controller = TextEditingController(text: value?.toString() ?? '');
      controller.addListener(() {
        _values[param.key] = controller.text;
        widget.onParametersChanged(Map<String, dynamic>.from(_values));
      });
      _textControllers[param.key] = controller;
    }

    if (notify) {
      widget.onParametersChanged(Map<String, dynamic>.from(_values));
    }

    setState(() {});
  }

  String? _normalizeName(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _helperText(ComponentParameter param) {
    final parts = <String>[];
    if (param.description != null && param.description!.isNotEmpty) {
      parts.add(param.description!);
    }
    parts.add('Key: ${param.key}');
    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final component = widget.component;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: component == null
            ? _buildEmptyState(context)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    enabled: widget.enabled,
                    decoration: InputDecoration(
                      labelText: 'Configuration name (optional)',
                      hintText: component.displayName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (component.parameters.isEmpty)
                    Text(
                      'This component does not require any parameters.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...component.parameters.map((param) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildParameterField(param),
                        )),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
          child: Text(
            'Select a component to configure its parameters.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildParameterField(ComponentParameter param) {
    switch (param.type.toLowerCase()) {
      case 'boolean':
      case 'bool':
        final current = (_values[param.key] == true);
        final helper = _helperText(param);
        return SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: Text(param.label),
          subtitle: helper != null ? Text(helper) : null,
          value: current,
          onChanged: widget.enabled
              ? (value) {
                  setState(() {
                    _values[param.key] = value;
                  });
                  widget.onParametersChanged(Map<String, dynamic>.from(_values));
                }
              : null,
        );
      default:
        if (param.hasOptions) {
          final current = (_values[param.key] ?? '') as String;
          return DropdownButtonFormField<String>(
            value: param.options.any((o) => o.value == current)
                ? current
                : (param.options.isNotEmpty ? param.options.first.value : null),
            items: param.options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: widget.enabled
                ? (value) {
                    if (value == null) return;
                    setState(() {
                      _values[param.key] = value;
                    });
                    widget.onParametersChanged(Map<String, dynamic>.from(_values));
                  }
                : null,
            validator: (value) {
              if (param.required && (value == null || value.isEmpty)) {
                return 'Required field';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: param.label,
              helperText: _helperText(param),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        final controller = _textControllers[param.key];
        if (controller == null) {
          return const SizedBox.shrink();
        }

        return TextFormField(
          controller: controller,
          enabled: widget.enabled,
          keyboardType: const ['number', 'integer', 'float', 'double']
                  .contains(param.type.toLowerCase())
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: param.label,
            helperText: _helperText(param),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (!param.required) return null;
            if (value == null || value.trim().isEmpty) {
              return 'Required field';
            }
            return null;
          },
        );
    }
  }
}
