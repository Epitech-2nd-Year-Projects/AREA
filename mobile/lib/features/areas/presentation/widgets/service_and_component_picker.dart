import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
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
  State<ServiceAndComponentPicker> createState() =>
      _ServiceAndComponentPickerState();
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
        if (widget.selectedComponentId == null) {
          widget.onComponentChanged(null);
          widget.onComponentSelected(null);
        }

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
        selected = _components.firstWhere(
          (c) => c.id == widget.selectedComponentId,
        );
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
    final l10n = AppLocalizations.of(context)!;
    final badge = _buildBadge(context, l10n);

    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.3)
          : AppColors.gray300.withValues(alpha: 0.2),
      color: AppColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.kind == ServiceComponentKind.action
                        ? Icons.flash_on_rounded
                        : Icons.settings_suggest_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.getTextPrimaryColor(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                badge,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Semantics(
              label: 'Select ${widget.title.toLowerCase()} service',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onSelectService,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceVariantColor(
                        context,
                      ).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.getBorderColor(
                          context,
                        ).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.apps_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            widget.providerLabel ??
                                'Select ${widget.title.toLowerCase()} service',
                            style: AppTypography.bodyLarge.copyWith(
                              color: widget.providerLabel != null
                                  ? AppColors.getTextPrimaryColor(context)
                                  : AppColors.getTextSecondaryColor(context),
                              fontWeight: widget.providerLabel != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            if (widget.providerId != null) ...[
              if (_loading)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Loading components...',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_loading)
                _components.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                l10n.noComponentsFor,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.getTextPrimaryColor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Semantics(
                        label: 'Component selection dropdown',
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue:
                              (widget.selectedComponentId != null &&
                                  _components.any(
                                    (e) => e.id == widget.selectedComponentId,
                                  ))
                              ? widget.selectedComponentId
                              : null,
                          hint: Text(l10n.chooseComponent),
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.primary,
                          ),
                          items: _components
                              .map(
                                (component) => DropdownMenuItem<String>(
                                  value: component.id,
                                  child: Text(
                                    component.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                              )
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
                          validator: (v) =>
                              v == null ? l10n.selectComponent : null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.getSurfaceVariantColor(
                              context,
                            ).withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.getBorderColor(
                                  context,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.getBorderColor(
                                  context,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.error,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, AppLocalizations l10n) {
    if (widget.providerId == null) return const SizedBox.shrink();

    final cubit = context.read<AreaFormCubit>();
    final cached = cubit.isServiceSubscribedSync(widget.providerId!);

    if (cached == null) {
      cubit.checkSubscriptionActive(widget.providerId!);
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceVariantColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.checking,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.getTextSecondaryColor(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    final isSub = widget.isSubscribed ?? cached;
    final color = isSub ? AppColors.success : AppColors.error;
    final icon = isSub ? Icons.check_circle_rounded : Icons.cancel_outlined;
    final text = isSub ? l10n.subscribed : l10n.notSubscribed;

    return Semantics(
      label: 'Subscription status: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
