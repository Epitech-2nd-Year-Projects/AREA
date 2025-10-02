import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/area.dart';
import '../../domain/repositories/area_repository.dart';
import '../cubits/area_form_cubit.dart';
import '../cubits/area_form_state.dart';
import '../../../services/domain/repositories/services_repository.dart';

import '../widgets/service_and_component_picker.dart';
import '../widgets/service_picker_sheet.dart';

class AreaFormPage extends StatelessWidget {
  final Area? areaToEdit;
  const AreaFormPage({super.key, this.areaToEdit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AreaFormCubit(
        sl<AreaRepository>(),
        sl<ServicesRepository>(),
        initialArea: areaToEdit,
      )..primeSubscriptionCache(),
      child: _AreaFormScreen(),
    );
  }
}

class _AreaFormScreen extends StatefulWidget {
  @override
  State<_AreaFormScreen> createState() => _AreaFormScreenState();
}

class _AreaFormScreenState extends State<_AreaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  bool _isActive = true;

  String? _actionProviderId;
  String? _actionProviderLabel;
  bool? _actionIsSubscribed;
  String? _actionComponentId;

  String? _reactionProviderId;
  String? _reactionProviderLabel;
  bool? _reactionIsSubscribed;
  String? _reactionComponentId;

  @override
  void initState() {
    super.initState();
    final initial = context.read<AreaFormCubit>().initialArea;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickActionService() async {
    final res = await showServicePickerSheet(context, title: 'Select Action Service');
    if (res == null) return;

    if (!res.isSubscribed) {
      final go = await _confirmSubscribe(res.providerName);
      if (go) {
        await context.push('/services/${res.providerId}');
        await context.read<AreaFormCubit>().primeSubscriptionCache();
      }
      return;
    }

    setState(() {
      _actionProviderId = res.providerId;
      _actionProviderLabel = res.providerName;
      _actionIsSubscribed = res.isSubscribed;
      _actionComponentId = null;
    });
  }

  Future<void> _pickReactionService() async {
    final res = await showServicePickerSheet(context, title: 'Select Reaction Service');
    if (res == null) return;

    if (!res.isSubscribed) {
      final go = await _confirmSubscribe(res.providerName);
      if (go) {
        await context.push('/services');
        await context.read<AreaFormCubit>().primeSubscriptionCache();
      }
      return;
    }

    setState(() {
      _reactionProviderId = res.providerId;
      _reactionProviderLabel = res.providerName;
      _reactionIsSubscribed = res.isSubscribed;
      _reactionComponentId = null;
    });
  }

  Future<bool> _confirmSubscribe(String serviceName) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Not subscribed'),
            content: Text('You are not subscribed to "$serviceName". Subscribe now?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Go to Services')),
            ],
          ),
        ) ??
        false;
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_actionProviderId == null || _reactionProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick Action & Reaction services')),
      );
      return;
    }
    if (_actionComponentId == null || _reactionComponentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick Action & Reaction components')),
      );
      return;
    }

    context.read<AreaFormCubit>().submit(
          name: _nameCtrl.text.trim(),
          isActive: _isActive,
          actionName: _actionComponentId!,
          reactionName: _reactionComponentId!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AreaFormCubit>();
    final isEdit = cubit.initialArea != null;

    return BlocConsumer<AreaFormCubit, AreaFormState>(
      listener: (context, state) {
        if (state is AreaFormSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Area saved successfully!')));
          context.pop(true);
        } else if (state is AreaFormError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isSubmitting = state is AreaFormSubmitting;

        return Scaffold(
          appBar: AppBar(title: Text(isEdit ? 'Edit Area' : 'New Area')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
              final horizontalPadding = isWide ? 48.0 : (isTablet ? 24.0 : 16.0);
              const maxContentWidth = 1100.0;

              final content = Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Wrap(
                            runSpacing: 12,
                            spacing: 16,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: isWide ? 420 : (isTablet ? 380 : double.infinity),
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    hintText: 'Enter area name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
                                  enabled: !isSubmitting,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Active'),
                                  Switch(
                                    value: _isActive,
                                    onChanged: isSubmitting ? null : (v) => setState(() => _isActive = v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ServiceAndComponentPicker(
                                title: 'Action',
                                providerId: _actionProviderId,
                                providerLabel: _actionProviderLabel,
                                isSubscribed: _actionIsSubscribed,
                                selectedComponentId: _actionComponentId,
                                kind: ServiceComponentKind.action,
                                onSelectService: _pickActionService,
                                onComponentChanged: (id) => setState(() => _actionComponentId = id),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ServiceAndComponentPicker(
                                title: 'Reaction',
                                providerId: _reactionProviderId,
                                providerLabel: _reactionProviderLabel,
                                isSubscribed: _reactionIsSubscribed,
                                selectedComponentId: _reactionComponentId,
                                kind: ServiceComponentKind.reaction,
                                onSelectService: _pickReactionService,
                                onComponentChanged: (id) => setState(() => _reactionComponentId = id),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            ServiceAndComponentPicker(
                              title: 'Action',
                              providerId: _actionProviderId,
                              providerLabel: _actionProviderLabel,
                              isSubscribed: _actionIsSubscribed,
                              selectedComponentId: _actionComponentId,
                              kind: ServiceComponentKind.action,
                              onSelectService: _pickActionService,
                              onComponentChanged: (id) => setState(() => _actionComponentId = id),
                            ),
                            const SizedBox(height: 16),
                            ServiceAndComponentPicker(
                              title: 'Reaction',
                              providerId: _reactionProviderId,
                              providerLabel: _reactionProviderLabel,
                              isSubscribed: _reactionIsSubscribed,
                              selectedComponentId: _reactionComponentId,
                              kind: ServiceComponentKind.reaction,
                              onSelectService: _pickReactionService,
                              onComponentChanged: (id) => setState(() => _reactionComponentId = id),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save),
                          label: Text(isEdit ? 'Save' : 'Create'),
                          onPressed: isSubmitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: content,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
