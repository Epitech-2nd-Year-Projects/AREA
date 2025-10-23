import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/area_draft.dart';
import '../../domain/repositories/area_repository.dart';
import '../cubits/area_form_cubit.dart';
import '../cubits/area_form_state.dart';
import '../../../services/domain/repositories/services_repository.dart';
import '../../../services/domain/entities/service_component.dart';

import '../widgets/service_and_component_picker.dart';
import '../widgets/service_picker_sheet.dart';
import '../widgets/component_configuration_form.dart';

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

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;

  String? _actionProviderId;
  String? _actionProviderLabel;
  bool? _actionIsSubscribed;
  String? _actionComponentId;
  ServiceComponent? _actionComponent;
  String? _actionComponentName;
  Map<String, dynamic> _actionParams = {};

  String? _reactionProviderId;
  String? _reactionProviderLabel;
  bool? _reactionIsSubscribed;
  String? _reactionComponentId;
  ServiceComponent? _reactionComponent;
  String? _reactionComponentName;
  Map<String, dynamic> _reactionParams = {};

  @override
  void initState() {
    super.initState();
    final initial = context.read<AreaFormCubit>().initialArea;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _descriptionCtrl =
        TextEditingController(text: initial?.description ?? '');

    if (initial != null) {
      final action = initial.action;
      _actionProviderId = action.component.provider.id;
      _actionProviderLabel = action.component.provider.displayName;
      _actionIsSubscribed = true;
      _actionComponentId = action.component.id;
      _actionComponent = action.component;
      _actionComponentName = action.name ?? action.component.displayName;
      _actionParams = Map<String, dynamic>.from(action.params);

      if (initial.reactions.isNotEmpty) {
        final reaction = initial.reactions.first;
        _reactionProviderId = reaction.component.provider.id;
        _reactionProviderLabel = reaction.component.provider.displayName;
        _reactionIsSubscribed = true;
        _reactionComponentId = reaction.component.id;
        _reactionComponent = reaction.component;
        _reactionComponentName =
            reaction.name ?? reaction.component.displayName;
        _reactionParams = Map<String, dynamic>.from(reaction.params);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickActionService() async {
    final res = await showServicePickerSheet(context, title:  AppLocalizations.of(context)!
        .selectActionService);
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
    });
    _updateActionComponent(null);
  }

  Future<void> _pickReactionService() async {
    final res = await showServicePickerSheet(context, title: AppLocalizations.of(context)!.selectReactionService);
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
    });
    _updateReactionComponent(null);
  }

  Future<bool> _confirmSubscribe(String serviceName) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.notSubscribedTitle),
            content: Text('You are not subscribed to "$serviceName". Subscribe now?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text(l10n.goToServices)),
            ],
          ),
        ) ??
        false;
  }

  void _updateActionComponent(ServiceComponent? component) {
    var changed = false;
    setState(() {
      final previousId = _actionComponentId;
      _actionComponent = component;
      _actionComponentId = component?.id;
      changed = _actionComponentId != previousId;
      if (changed) {
        _actionComponentName = component?.displayName;
        _actionParams = {};
      }
    });

    if (changed && component != null) {
      _primeActionDefaults(component);
    }
  }

  void _updateReactionComponent(ServiceComponent? component) {
    var changed = false;
    setState(() {
      final previousId = _reactionComponentId;
      _reactionComponent = component;
      _reactionComponentId = component?.id;
      changed = _reactionComponentId != previousId;
      if (changed) {
        _reactionComponentName = component?.displayName;
        _reactionParams = {};
      }
    });

    if (changed && component != null) {
      _primeReactionDefaults(component);
    }
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final l10n =  AppLocalizations.of(context)!;

    if (_actionProviderId == null || _reactionProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectActionReactionServices)),
      );
      return;
    }
    if (_actionComponentId == null || _reactionComponentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectActionReactionComponents)),
      );
      return;
    }

    final actionDraft = AreaComponentDraft(
      componentId: _actionComponentId!,
      name: _normalizeName(_actionComponentName),
      params: Map<String, dynamic>.from(_actionParams),
    );

    final reactionDraft = AreaComponentDraft(
      componentId: _reactionComponentId!,
      name: _normalizeName(_reactionComponentName),
      params: Map<String, dynamic>.from(_reactionParams),
    );

    context.read<AreaFormCubit>().submit(
          name: _nameCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          action: actionDraft,
          reactions: [reactionDraft],
        );
  }

  String? _normalizeName(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _primeActionDefaults(ServiceComponent component) async {
    final cubit = context.read<AreaFormCubit>();
    final suggestions = await cubit.suggestParametersFor(component);
    if (!mounted) return;
    if (_actionComponent?.id != component.id) return;
    if (_actionParams.isNotEmpty) return;
    if (suggestions.isEmpty) return;

    setState(() {
      _actionParams = Map<String, dynamic>.from(suggestions);
    });
  }

  Future<void> _primeReactionDefaults(ServiceComponent component) async {
    final cubit = context.read<AreaFormCubit>();
    final suggestions = await cubit.suggestParametersFor(component);
    if (!mounted) return;
    if (_reactionComponent?.id != component.id) return;
    if (_reactionParams.isNotEmpty) return;
    if (suggestions.isEmpty) return;

    setState(() {
      _reactionParams = Map<String, dynamic>.from(suggestions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AreaFormCubit>();
    final isEdit = cubit.initialArea != null;

    return BlocConsumer<AreaFormCubit, AreaFormState>(
      listener: (context, state) {
        if (state is AreaFormSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.areaSaved)));
          context.pop(true);
        } else if (state is AreaFormError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isSubmitting = state is AreaFormSubmitting;

        return Scaffold(
          backgroundColor: AppColors.getBackgroundColor(context),
          appBar: AppBar(
            title: Text(
              isEdit ? l10n.editArea : l10n.newArea,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            centerTitle: false,
            elevation: 0,
            backgroundColor: AppColors.getSurfaceColor(context),
            surfaceTintColor: Colors.transparent,
            leading: Semantics(
              label: 'Back',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
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
                      _buildHeaderCard(context, isSubmitting, l10n),
                      const SizedBox(height: 16),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildActionPicker(isSubmitting, l10n)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildReactionPicker(isSubmitting, l10n)),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildActionPicker(isSubmitting, l10n),
                            const SizedBox(height: 16),
                            _buildReactionPicker(isSubmitting, l10n),
                          ],
                        ),
                      const SizedBox(height: 16),
                      ComponentConfigurationForm(
                        title: l10n.actionConfiguration,
                        component: _actionComponent,
                        initialName: _actionComponentName,
                        initialValues: _actionParams,
                        enabled: !isSubmitting,
                        onNameChanged: (value) => _actionComponentName = value,
                        onParametersChanged: (values) => _actionParams = values,
                      ),
                      const SizedBox(height: 16),
                      ComponentConfigurationForm(
                        title: l10n.reactionConfiguration,
                        component: _reactionComponent,
                        initialName: _reactionComponentName,
                        initialValues: _reactionParams,
                        enabled: !isSubmitting,
                        onNameChanged: (value) => _reactionComponentName = value,
                        onParametersChanged: (values) => _reactionParams = values,
                      ),
                      const SizedBox(height: 32),
                      Semantics(
                        label: '${isEdit ? l10n.editButton : l10n.createButton} button',
                        button: true,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 24),
                            label: Text(
                              isEdit ? l10n.editButton : l10n.createButton,
                              style: AppTypography.labelLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: isSubmitting ? 0 : 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildHeaderCard(BuildContext context, bool isSubmitting, AppLocalizations l10n) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.getBorderColor(context), width: 2),
    );
    return Card(
      elevation: 0,
      color: AppColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.nameYourAutomation,
                border: border,
                enabledBorder: border,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: border,
                focusedErrorBorder: border,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.nameCannotBeEmpty
                  : null,
              enabled: !isSubmitting,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                hintText: l10n.addContextToRemember,
                border: border,
                enabledBorder: border,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: border,
                focusedErrorBorder: border,
              ),
              enabled: !isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPicker(bool isSubmitting, AppLocalizations l10n) {
    return ServiceAndComponentPicker(
      title: l10n.action,
      providerId: _actionProviderId,
      providerLabel: _actionProviderLabel,
      isSubscribed: _actionIsSubscribed,
      selectedComponentId: _actionComponentId,
      kind: ServiceComponentKind.action,
      onSelectService: isSubmitting ? () {} : _pickActionService,
      onComponentChanged: (id) {
        if (id == null) {
          _updateActionComponent(null);
        }
      },
      onComponentSelected: _updateActionComponent,
    );
  }

  Widget _buildReactionPicker(bool isSubmitting, AppLocalizations l10n) {
    return ServiceAndComponentPicker(
      title: l10n.reaction,
      providerId: _reactionProviderId,
      providerLabel: _reactionProviderLabel,
      isSubscribed: _reactionIsSubscribed,
      selectedComponentId: _reactionComponentId,
      kind: ServiceComponentKind.reaction,
      onSelectService: isSubmitting ? () {} : _pickReactionService,
      onComponentChanged: (id) {
        if (id == null) {
          _updateReactionComponent(null);
        }
      },
      onComponentSelected: _updateReactionComponent,
    );
  }
}
