import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    final filtered = _items.where((s) {
      final dn = (s.provider.displayName.isNotEmpty)
          ? s.provider.displayName.toLowerCase()
          : s.provider.name.toLowerCase();
      if (_query.isNotEmpty && !dn.contains(_query)) return false;
      if (_onlySubscribed && !s.isSubscribed) return false;
      return true;
    }).toList();

    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.getTextTertiaryColor(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                widget.title,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Search services field',
                    child: TextField(
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        hintText: l10n.searchServices,
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.getTextTertiaryColor(context),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.5),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Semantics(
                  label: 'Filter subscribed only',
                  child: FilterChip(
                    label: Text(
                      l10n.subscribedOnly,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _onlySubscribed,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: _onlySubscribed
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.getBorderColor(context).withValues(alpha: 0.3),
                    ),
                    backgroundColor: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.3),
                    onSelected: (v) => setState(() => _onlySubscribed = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getBorderColor(context).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.subscribed,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.notSubscribedStatus,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Loading services...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: AppColors.getTextTertiaryColor(context),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'No services found',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Try adjusting your search or filters',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xl * 2.4,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final s = filtered[i];
                    final name = ((s.provider.displayName.isNotEmpty) == true)
                        ? s.provider.displayName
                        : s.provider.name;
                    final icon = s.isSubscribed
                        ? Icons.check_circle_rounded
                        : Icons.cancel_outlined;
                    final color = s.isSubscribed ? AppColors.success : AppColors.error;

                    return Semantics(
                      label: '$name service, ${s.isSubscribed ? "subscribed" : "not subscribed"}',
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(ServicePickResult(
                            providerId: s.provider.id,
                            providerName: name,
                            isSubscribed: s.isSubscribed,
                          )),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.getSurfaceVariantColor(context).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.characters.first.toUpperCase(),
                                      style: AppTypography.headlineMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.getTextPrimaryColor(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Row(
                                        children: [
                                          Icon(icon, color: color, size: 14),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            s.isSubscribed
                                                ? l10n.subscribed
                                                : l10n.notSubscribedStatus,
                                            style: AppTypography.labelMedium.copyWith(
                                              color: color,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.getTextTertiaryColor(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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