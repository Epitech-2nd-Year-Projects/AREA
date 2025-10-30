import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/area_template.dart';
import '../../domain/entities/area_draft.dart';
import '../../domain/repositories/area_repository.dart';
import '../cubits/area_form_cubit.dart';
import '../cubits/area_form_state.dart';
import '../../../services/domain/repositories/services_repository.dart';
import '../../../services/domain/entities/service_component.dart';
import '../../../services/domain/value_objects/component_kind.dart';

import '../widgets/service_and_component_picker.dart';
import '../widgets/service_picker_sheet.dart';
import '../widgets/component_configuration_form.dart';

class AreaFormPage extends StatelessWidget {
  final Area? areaToEdit;
  final AreaTemplate? template;
  final ServiceComponent? initialComponent;
  const AreaFormPage({
    super.key,
    this.areaToEdit,
    this.template,
    this.initialComponent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AreaFormCubit(
        sl<AreaRepository>(),
        sl<ServicesRepository>(),
        initialArea: areaToEdit,
      )..primeSubscriptionCache(),
      child: _AreaFormScreen(template: template, initialComponent: initialComponent),
    );
  }
}

class _AreaFormScreen extends StatefulWidget {
  final AreaTemplate? template;
  final ServiceComponent? initialComponent;

  const _AreaFormScreen({this.template, this.initialComponent});

  @override
  State<_AreaFormScreen> createState() => _AreaFormScreenState();
}

class _ReactionSelection {
  String? providerId;
  String? providerLabel;
  bool? isSubscribed;
  String? componentId;
  ServiceComponent? component;
  String? componentName;
  Map<String, dynamic> params;

  _ReactionSelection({
    this.providerId,
    this.providerLabel,
    this.isSubscribed,
    this.componentId,
    this.component,
    this.componentName,
    Map<String, dynamic>? params,
  }) : params = params ?? <String, dynamic>{};

  bool get hasSelection => providerId != null || componentId != null;

  void reset() {
    providerId = null;
    providerLabel = null;
    isSubscribed = null;
    componentId = null;
    component = null;
    componentName = null;
    params = <String, dynamic>{};
  }
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

  final List<_ReactionSelection> _reactions = <_ReactionSelection>[];

  @override
  void initState() {
    super.initState();
    final initial = context.read<AreaFormCubit>().initialArea;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _descriptionCtrl = TextEditingController(text: initial?.description ?? '');

    if (initial != null) {
      final action = initial.action;
      _actionProviderId = action.component.provider.id;
      _actionProviderLabel = action.component.provider.displayName;
      _actionIsSubscribed = true;
      _actionComponentId = action.component.id;
      _actionComponent = action.component;
      _actionComponentName = action.name ?? action.component.displayName;
      _actionParams = Map<String, dynamic>.from(action.params);

      for (final reaction in initial.reactions) {
        _reactions.add(
          _ReactionSelection(
            providerId: reaction.component.provider.id,
            providerLabel: reaction.component.provider.displayName,
            isSubscribed: true,
            componentId: reaction.component.id,
            component: reaction.component,
            componentName: reaction.name ?? reaction.component.displayName,
            params: Map<String, dynamic>.from(reaction.params),
          ),
        );
      }
    }

    if (_reactions.isEmpty) {
      _reactions.add(_ReactionSelection());
    }

    final template = widget.template;
    final initialComponent = widget.initialComponent;
    
    if (template != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyTemplate(template);
        }
      });
    } else if (initialComponent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyInitialComponent(initialComponent);
        }
      });
    }
  }

  Widget _buildActionSection(
    bool isSubmitting,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionPicker(isSubmitting, l10n),
        const SizedBox(height: 16),
        ComponentConfigurationForm(
          key: ValueKey('action-config-${_actionComponentId ?? 'none'}'),
          title: l10n.actionConfiguration,
          component: _actionComponent,
          initialName: _actionComponentName,
          initialValues: _actionParams,
          enabled: !isSubmitting,
          onNameChanged: (value) => _actionComponentName = value,
          onParametersChanged: (values) => _actionParams = values,
        ),
      ],
    );
  }

  Widget _buildReactionsSection(
    bool isSubmitting,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _reactions.length; i++) ...[
          _buildReactionBlock(i, isSubmitting, l10n),
          if (i != _reactions.length - 1) const SizedBox(height: 24),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 360.0;
            final buttonWidth = availableWidth < 360.0
                ? availableWidth
                : 360.0;

            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: buttonWidth,
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : _addReaction,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addReaction),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _addReaction() {
    FocusScope.of(context).unfocus();
    setState(() {
      _reactions.add(_ReactionSelection());
    });
  }

  void _removeReaction(int index) {
    if (index < 0 || index >= _reactions.length) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      if (_reactions.length == 1) {
        _reactions.first.reset();
      } else {
        _reactions.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickActionService() async {
    final res = await showServicePickerSheet(
      context,
      title: AppLocalizations.of(context)!.selectActionService,
    );
    if (res == null) return;

    if (!res.isSubscribed) {
      final go = await _confirmSubscribe(res.providerName);
      if (go && mounted) {
        await context.push('/services/${res.providerId}');
        if (mounted) {
          await context.read<AreaFormCubit>().primeSubscriptionCache();
        }
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

  Future<void> _pickReactionService(int index) async {
    final res = await showServicePickerSheet(
      context,
      title: AppLocalizations.of(context)!.selectReactionService,
    );
    if (res == null) return;

    if (!res.isSubscribed) {
      final go = await _confirmSubscribe(res.providerName);
      if (go && mounted) {
        await context.push('/services/${res.providerId}');
        if (mounted) {
          await context.read<AreaFormCubit>().primeSubscriptionCache();
        }
      }
      return;
    }

    setState(() {
      final entry = _reactions[index];
      entry.providerId = res.providerId;
      entry.providerLabel = res.providerName;
      entry.isSubscribed = res.isSubscribed;
      entry.componentId = null;
      entry.component = null;
      entry.componentName = null;
      entry.params = <String, dynamic>{};
    });
    _updateReactionComponent(index, null);
  }

  Future<bool> _confirmSubscribe(String serviceName) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.notSubscribedTitle),
            content: Text(
              l10n.notSubscribedMessage(serviceName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text(l10n.goToServices),
              ),
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

  void _updateReactionComponent(int index, ServiceComponent? component) {
    var changed = false;
    setState(() {
      final entry = _reactions[index];
      final previousId = entry.componentId;
      entry.component = component;
      entry.componentId = component?.id;
      changed = entry.componentId != previousId;
      if (changed) {
        entry.componentName = component?.displayName;
        entry.params = <String, dynamic>{};
      }
    });

    if (changed && component != null) {
      _primeReactionDefaults(index, component);
    }
  }

  Future<void> _applyTemplate(AreaTemplate template) async {
    final cubit = context.read<AreaFormCubit>();

    await cubit.primeSubscriptionCache();

    final actionComponents = await cubit.getComponentsFor(
      template.action.providerId,
      kind: ComponentKind.action,
    );
    final reactionComponents = await cubit.getComponentsFor(
      template.reaction.providerId,
      kind: ComponentKind.reaction,
    );

    ServiceComponent? _matchComponent(
      List<ServiceComponent> components,
      String componentName,
    ) {
      for (final component in components) {
        if (component.name == componentName) {
          return component;
        }
      }
      return null;
    }

    final actionComponent = _matchComponent(
      actionComponents,
      template.action.componentName,
    );
    final reactionComponent = _matchComponent(
      reactionComponents,
      template.reaction.componentName,
    );

    if (actionComponent == null || reactionComponent == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template components are not available right now.'),
        ),
      );
      return;
    }

    cubit.overwriteSubscriptionInCache(template.action.providerId, true);
    cubit.overwriteSubscriptionInCache(template.reaction.providerId, true);

    if (!mounted) return;

    setState(() {
      _nameCtrl.text = template.suggestedName;
      if (template.suggestedDescription != null) {
        _descriptionCtrl.text = template.suggestedDescription!;
      }

      _actionProviderId = template.action.providerId;
      _actionProviderLabel = actionComponent.provider.displayName;
      _actionIsSubscribed =
          cubit.subscriptionCache[template.action.providerId] ?? true;
      _actionComponent = actionComponent;
      _actionComponentId = actionComponent.id;
      _actionComponentName = actionComponent.displayName;
      _actionParams = Map<String, dynamic>.from(template.action.defaultParams);

      _reactions
        ..clear()
        ..add(
          _ReactionSelection(
            providerId: template.reaction.providerId,
            providerLabel: reactionComponent.provider.displayName,
            isSubscribed:
                cubit.subscriptionCache[template.reaction.providerId] ?? true,
            component: reactionComponent,
            componentId: reactionComponent.id,
            componentName: reactionComponent.displayName,
            params: Map<String, dynamic>.from(
              template.reaction.defaultParams,
            ),
          ),
        );
    });

    await _primeActionDefaults(actionComponent);
    await _primeReactionDefaults(0, reactionComponent);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _applyInitialComponent(ServiceComponent component) async {
    final cubit = context.read<AreaFormCubit>();

    await cubit.primeSubscriptionCache();

    if (component.isAction) {
      setState(() {
        _actionProviderId = component.provider.id;
        _actionProviderLabel = component.provider.displayName;
        _actionIsSubscribed = true;
        _actionComponent = component;
        _actionComponentId = component.id;
        _actionComponentName = component.displayName;
        _actionParams = {};
      });

      if (mounted) {
        await _primeActionDefaults(component);
      }
    } else {
      setState(() {
        final entry = _reactions.first;
        entry.providerId = component.provider.id;
        entry.providerLabel = component.provider.displayName;
        entry.isSubscribed = true;
        entry.component = component;
        entry.componentId = component.id;
        entry.componentName = component.displayName;
        entry.params = <String, dynamic>{};
      });

      if (mounted) {
        await _primeReactionDefaults(0, component);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final l10n = AppLocalizations.of(context)!;

    if (_actionProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectActionReactionServices)),
      );
      return;
    }
    if (_actionComponentId == null) {
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

    final reactionDrafts = <AreaComponentDraft>[];
    for (final entry in _reactions) {
      final hasProvider = entry.providerId != null;
      final hasComponent = entry.componentId != null;

      if (!hasProvider && !hasComponent) {
        continue;
      }

      if (!hasProvider || !hasComponent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.completeReactionSelection)),
        );
        return;
      }

      reactionDrafts.add(
        AreaComponentDraft(
          componentId: entry.componentId!,
          name: _normalizeName(entry.componentName),
          params: Map<String, dynamic>.from(entry.params),
        ),
      );
    }

    if (reactionDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.atLeastOneReaction)),
      );
      return;
    }

    context.read<AreaFormCubit>().submit(
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      action: actionDraft,
      reactions: reactionDrafts,
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

    if (_actionComponent?.id != component.id) {
      return;
    }

    if (suggestions.isEmpty) return;

    setState(() {
      _actionParams = {..._actionParams, ...suggestions};
    });
  }

  Future<void> _primeReactionDefaults(
    int index,
    ServiceComponent component,
  ) async {
    final cubit = context.read<AreaFormCubit>();
    final suggestions = await cubit.suggestParametersFor(component);

    if (!mounted) return;

    if (index >= _reactions.length) return;
    final entry = _reactions[index];
    if (entry.component?.id != component.id) return;

    if (suggestions.isEmpty) return;

    setState(() {
      entry.params = {...entry.params, ...suggestions};
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.areaSaved)));
          context.pop(true);
        } else if (state is AreaFormError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
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
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 900;
              final horizontalPadding = isWide
                  ? 48.0
                  : (isTablet ? 24.0 : 16.0);
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
                            Expanded(
                              child: _buildActionSection(isSubmitting, l10n),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildReactionsSection(
                                isSubmitting,
                                l10n,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildActionSection(isSubmitting, l10n),
                            const SizedBox(height: 16),
                            _buildReactionsSection(isSubmitting, l10n),
                          ],
                        ),
                      const SizedBox(height: 32),
                      Semantics(
                        label:
                            '${isEdit ? l10n.editButton : l10n.createButton} button',
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.6),
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
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: 16,
                    bottom: 90,
                  ),
                  child: Align(alignment: Alignment.topCenter, child: content),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    bool isSubmitting,
    AppLocalizations l10n,
  ) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.getBorderColor(context),
        width: 2,
      ),
    );
    return Card(
      elevation: 0,
      color: AppColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getBorderColor(context)),
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
      key: ValueKey('action-picker-${_actionProviderId ?? 'none'}'),
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

  Widget _buildReactionPicker(
    int index,
    bool isSubmitting,
    AppLocalizations l10n,
  ) {
    final reaction = _reactions[index];

    return ServiceAndComponentPicker(
      key: ValueKey(
        'reaction-picker-$index-${reaction.providerId ?? 'none'}',
      ),
      title: l10n.reactionNumber(index + 1),
      providerId: reaction.providerId,
      providerLabel: reaction.providerLabel,
      isSubscribed: reaction.isSubscribed,
      selectedComponentId: reaction.componentId,
      kind: ServiceComponentKind.reaction,
      onSelectService:
          isSubmitting ? () {} : () => _pickReactionService(index),
      onComponentChanged: (id) {
        if (id == null) {
          _updateReactionComponent(index, null);
        }
      },
      onComponentSelected: (component) =>
          _updateReactionComponent(index, component),
      onRemove: _reactions.length > 1 ? () => _removeReaction(index) : null,
      removeTooltip: l10n.removeReaction,
    );
  }

  Widget _buildReactionBlock(
    int index,
    bool isSubmitting,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildReactionPicker(index, isSubmitting, l10n),
        const SizedBox(height: 16),
        ComponentConfigurationForm(
          key: ValueKey(
            'reaction-config-$index-${_reactions[index].componentId ?? 'none'}',
          ),
          title: l10n.reactionConfigurationNumber(index + 1),
          component: _reactions[index].component,
          initialName: _reactions[index].componentName,
          initialValues: _reactions[index].params,
          enabled: !isSubmitting,
          onNameChanged: (value) => _reactions[index].componentName = value,
          onParametersChanged: (values) {
            _reactions[index].params = Map<String, dynamic>.from(values);
          },
        ),
      ],
    );
  }
}
