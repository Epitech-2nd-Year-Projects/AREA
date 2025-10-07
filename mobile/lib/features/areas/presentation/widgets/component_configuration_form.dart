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
        } else if (_isBooleanParam(param)) {
          value = false;
        } else if (param.hasOptions) {
          value = param.options.first.value;
        } else {
          value = '';
        }
      }

      if (_isBooleanParam(param) && value is! bool) {
        value = value == true || value == 'true';
      }

      if (param.hasOptions) {
        final options = param.options.map((o) => o.value).toSet();
        if (!options.contains(value)) {
          value = param.options.first.value;
        }
      }

      value = _sanitizeValueForParam(param, value);
      _values[param.key] = value;

      if (_isBooleanParam(param) || param.hasOptions) {
        continue;
      }

      final controller =
          TextEditingController(text: _displayTextForParam(param, value));
      if (!_isDateRelatedParam(param)) {
        controller.addListener(() {
          _values[param.key] = controller.text;
          widget.onParametersChanged(Map<String, dynamic>.from(_values));
        });
      }
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
    if (_isBooleanParam(param)) {
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
    }

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

    if (_isDateTimeParam(param)) {
      return _buildDateTimePicker(param);
    }

    if (_isDateParam(param)) {
      return _buildDatePicker(param);
    }

    if (_isTimeParam(param)) {
      return _buildTimePicker(param);
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

  bool _isBooleanParam(ComponentParameter param) {
    final type = param.type.toLowerCase();
    return type == 'boolean' || type == 'bool';
  }

  bool _isDateRelatedParam(ComponentParameter param) {
    return _isDateTimeParam(param) || _isDateParam(param) || _isTimeParam(param);
  }

  bool _isDateTimeParam(ComponentParameter param) {
    final type = param.type.toLowerCase();
    if (type == 'datetime' || type == 'date-time' || type == 'datetime-local') {
      return true;
    }
    final format = param.extras['format'];
    if (format is String &&
        (format.toLowerCase() == 'date-time' || format.toLowerCase() == 'datetime')) {
      return true;
    }
    final kind = param.extras['type'];
    if (kind is String &&
        (kind.toLowerCase() == 'date-time' || kind.toLowerCase() == 'datetime')) {
      return true;
    }
    return false;
  }

  bool _isDateParam(ComponentParameter param) {
    final type = param.type.toLowerCase();
    if (type == 'date') {
      return true;
    }
    final format = param.extras['format'];
    if (format is String && format.toLowerCase() == 'date') {
      return true;
    }
    return false;
  }

  bool _isTimeParam(ComponentParameter param) {
    final type = param.type.toLowerCase();
    if (type == 'time') {
      return true;
    }
    final format = param.extras['format'];
    if (format is String && format.toLowerCase() == 'time') {
      return true;
    }
    return false;
  }

  dynamic _sanitizeValueForParam(ComponentParameter param, dynamic value) {
    if (_isDateTimeParam(param)) {
      if (value is DateTime) {
        return value.toUtc().toIso8601String();
      }
      if (value is String && value.isNotEmpty) {
        final parsed = _parseDateTime(value);
        if (parsed != null) {
          return parsed.toUtc().toIso8601String();
        }
      }
      return value is String ? value : '';
    }

    if (_isDateParam(param)) {
      if (value is DateTime) {
        return _formatDateOnly(value);
      }
      if (value is String && value.isNotEmpty) {
        final parsed = _parseDate(value);
        if (parsed != null) {
          return _formatDateOnly(parsed);
        }
      }
      return value is String ? value : '';
    }

    if (_isTimeParam(param)) {
      if (value is TimeOfDay) {
        return _formatTimeOfDay(value);
      }
      if (value is String && value.isNotEmpty) {
        final parsed = _parseTime(value);
        if (parsed != null) {
          return _formatTimeOfDay(parsed);
        }
      }
      return value is String ? value : '';
    }

    return value;
  }

  String _displayTextForParam(ComponentParameter param, dynamic value) {
    if (value == null) return '';

    if (_isDateTimeParam(param)) {
      if (value is String && value.isNotEmpty) {
        final parsed = _parseDateTime(value);
        if (parsed != null) {
          return _formatDateTimeForDisplay(parsed);
        }
      }
      return '';
    }

    if (_isDateParam(param)) {
      if (value is String && value.isNotEmpty) {
        final parsed = _parseDate(value);
        if (parsed != null) {
          return _formatDateForDisplay(parsed);
        }
      }
      return '';
    }

    if (_isTimeParam(param)) {
      if (value is String && value.isNotEmpty) {
        final parsed = _parseTime(value);
        if (parsed != null) {
          return _formatTimeOfDay(parsed);
        }
        return value;
      }
      return '';
    }

    return value?.toString() ?? '';
  }

  Widget _buildDateTimePicker(ComponentParameter param) {
    final controller = _textControllers[param.key];
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? () => _pickDateTime(param) : null,
      decoration: InputDecoration(
        labelText: param.label,
        helperText: _helperText(param),
        hintText: controller.text.isEmpty ? 'Select date & time' : null,
        suffixIcon: const Icon(Icons.calendar_month),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (!param.required) return null;
        final raw = _values[param.key];
        if (raw == null || (raw is String && raw.trim().isEmpty)) {
          return 'Required field';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(ComponentParameter param) {
    final controller = _textControllers[param.key];
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? () => _pickDate(param) : null,
      decoration: InputDecoration(
        labelText: param.label,
        helperText: _helperText(param),
        hintText: controller.text.isEmpty ? 'Select date' : null,
        suffixIcon: const Icon(Icons.event),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (!param.required) return null;
        final raw = _values[param.key];
        if (raw == null || (raw is String && raw.trim().isEmpty)) {
          return 'Required field';
        }
        return null;
      },
    );
  }

  Widget _buildTimePicker(ComponentParameter param) {
    final controller = _textControllers[param.key];
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? () => _pickTime(param) : null,
      decoration: InputDecoration(
        labelText: param.label,
        helperText: _helperText(param),
        hintText: controller.text.isEmpty ? 'Select time' : null,
        suffixIcon: const Icon(Icons.schedule),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (!param.required) return null;
        final raw = _values[param.key];
        if (raw == null || (raw is String && raw.trim().isEmpty)) {
          return 'Required field';
        }
        return null;
      },
    );
  }

  Future<void> _pickDateTime(ComponentParameter param) async {
    if (!widget.enabled) return;

    final current = _values[param.key];
    DateTime initial = DateTime.now();
    if (current is String && current.isNotEmpty) {
      final parsed = _parseDateTime(current);
      if (parsed != null) {
        initial = parsed;
      }
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final iso = combined.toUtc().toIso8601String();
    setState(() {
      _values[param.key] = iso;
      final controller = _textControllers[param.key];
      controller?.text = _formatDateTimeForDisplay(combined);
    });
    widget.onParametersChanged(Map<String, dynamic>.from(_values));
  }

  Future<void> _pickDate(ComponentParameter param) async {
    if (!widget.enabled) return;

    final current = _values[param.key];
    DateTime initial = DateTime.now();
    if (current is String && current.isNotEmpty) {
      final parsed = _parseDate(current);
      if (parsed != null) {
        initial = parsed;
      }
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final formatted = _formatDateOnly(date);
    setState(() {
      _values[param.key] = formatted;
      final controller = _textControllers[param.key];
      controller?.text = _formatDateForDisplay(date);
    });
    widget.onParametersChanged(Map<String, dynamic>.from(_values));
  }

  Future<void> _pickTime(ComponentParameter param) async {
    if (!widget.enabled) return;

    final current = _values[param.key];
    TimeOfDay initial = TimeOfDay.now();
    if (current is String && current.isNotEmpty) {
      final parsed = _parseTime(current);
      if (parsed != null) {
        initial = parsed;
      }
    }

    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (time == null) return;

    final formatted = _formatTimeOfDay(time);
    setState(() {
      _values[param.key] = formatted;
      final controller = _textControllers[param.key];
      controller?.text = formatted;
    });
    widget.onParametersChanged(Map<String, dynamic>.from(_values));
  }

  DateTime? _parseDateTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      final parsed = DateTime.parse(trimmed);
      return parsed.isUtc ? parsed.toLocal() : parsed;
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      final parsed = DateTime.parse(trimmed);
      final local = parsed.isUtc ? parsed.toLocal() : parsed;
      return DateTime(local.year, local.month, local.day);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDateTimeForDisplay(DateTime value) {
    final local = value;
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _formatDateForDisplay(DateTime value) {
    return '${value.year}-${_twoDigits(value.month)}-${_twoDigits(value.day)}';
  }

  String _formatDateOnly(DateTime value) {
    final local = value;
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
