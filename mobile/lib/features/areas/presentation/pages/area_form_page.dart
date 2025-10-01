import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/area.dart';
import '../../domain/repositories/area_repository.dart';
import '../../domain/use_cases/create_area.dart';
import '../../domain/use_cases/update_area.dart';
import '../cubits/area_form_cubit.dart';
import '../cubits/area_form_state.dart';
import '../cubits/areas_cubit.dart';

class AreaFormPage extends StatelessWidget {
  final Area? areaToEdit;
  const AreaFormPage({super.key, this.areaToEdit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AreaFormCubit(
        createArea: CreateArea(sl<AreaRepository>()),
        updateArea: UpdateArea(sl<AreaRepository>()),
        initialArea: areaToEdit,
      ),
      child: _AreaFormScaffold(areaToEdit: areaToEdit),
    );
  }
}

class _AreaFormScaffold extends StatelessWidget {
  final Area? areaToEdit;
  const _AreaFormScaffold({required this.areaToEdit});

  @override
  Widget build(BuildContext context) {
    final isEdit = areaToEdit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Area' : 'New Area')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _AreaFormContent(area: areaToEdit),
      ),
    );
  }
}

class _AreaFormContent extends StatefulWidget {
  final Area? area;
  const _AreaFormContent({this.area});

  @override
  State<_AreaFormContent> createState() => _AreaFormContentState();
}

class _AreaFormContentState extends State<_AreaFormContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _isActive = true;

  String? _selectedAction;
  String? _selectedReaction;

  static const List<String> kActionOptions = [
    'issue_created',
    'mail_with_attachment',
  ];
  static const List<String> kReactionOptions = [
    'send_teams_message',
    'save_to_onedrive',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.area?.name ?? '');
    _isActive = widget.area?.isActive ?? true;

    _selectedAction = (widget.area != null && kActionOptions.contains(widget.area!.actionName))
        ? widget.area!.actionName
        : null;

    _selectedReaction = (widget.area != null && kReactionOptions.contains(widget.area!.reactionName))
        ? widget.area!.reactionName
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _labelForAction(String key) {
    switch (key) {
      case 'issue_created': return 'Issue GitHub created';
      case 'mail_with_attachment': return 'E-mail with attachment';
      default: return key;
    }
  }

  String _labelForReaction(String key) {
    switch (key) {
      case 'send_teams_message': return 'Send Teams message';
      case 'save_to_onedrive': return 'Save to OneDrive';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionItems = <String>{
      if (_selectedAction != null) _selectedAction!,
      ...kActionOptions,
    }.toList();

    final reactionItems = <String>{
      if (_selectedReaction != null) _selectedReaction!,
      ...kReactionOptions,
    }.toList();

    final actionValue = actionItems.contains(_selectedAction) ? _selectedAction : null;
    final reactionValue = reactionItems.contains(_selectedReaction) ? _selectedReaction : null;

    return BlocConsumer<AreaFormCubit, AreaFormState>(
      listener: (context, state) {
        if (state is AreaFormSuccess) {
          final areasCubit = context.findAncestorStateOfType<State>() != null
              ? context.read<AreasCubit?>()
              : null;
          areasCubit?.fetchAreas();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save successful!')),
          );
          context.pop();
        } else if (state is AreaFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is AreaFormSubmitting;

        return Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name of the automation'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Activate this Area'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Action'),
                initialValue: actionValue,
                hint: const Text('Choose an action'),
                items: actionItems
                    .map((e) => DropdownMenuItem(value: e, child: Text(_labelForAction(e))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAction = v),
                validator: (v) => v == null ? 'Select an action' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Reaction'),
                initialValue: reactionValue,
                hint: const Text('Choose a reaction'),
                items: reactionItems
                    .map((e) => DropdownMenuItem(value: e, child: Text(_labelForReaction(e))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedReaction = v),
                validator: (v) => v == null ? 'Select a reaction' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AreaFormCubit>().submit(
                                name: _nameCtrl.text.trim(),
                                isActive: _isActive,
                                actionName: _selectedAction!,
                                reactionName: _selectedReaction!,
                              );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.area == null ? 'Create' : 'Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
