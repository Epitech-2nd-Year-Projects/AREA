import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/accessibility_controller.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../domain/use_cases/get_server_address.dart';
import '../../domain/use_cases/set_server_address.dart';
import '../../domain/use_cases/probe_server_address.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(
        getServerAddress: GetServerAddress(sl<SettingsRepository>()),
        setServerAddress: SetServerAddress(sl<SettingsRepository>()),
        probeServerAddress: ProbeServerAddress(sl<SettingsRepository>()),
        accessibilityController: sl<AccessibilityController>(),
      )..load(),
      child: const _SettingsScreen(),
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  final _controller = TextEditingController();
  bool _hasAnnouncedPage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAnnouncedPage) return;
    _hasAnnouncedPage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      final direction = Directionality.of(context);
      final cubit = context.read<SettingsCubit>();
      final currentState = cubit.state;
      if (currentState is SettingsReady && currentState.isScreenReaderEnabled) {
        final summary = _buildScreenSummary(l10n, currentState);
        cubit.readCurrentScreen(summary, textDirection: direction);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _buildScreenSummary(AppLocalizations l10n, SettingsReady state) {
    final serverAddress = state.currentAddress.trim().isEmpty
        ? l10n.serverAddressHint
        : state.currentAddress;
    final colorBlindStatus =
        state.isColorBlindModeEnabled ? l10n.enabled : l10n.disabled;
    final screenReaderStatus =
        state.isScreenReaderEnabled ? l10n.enabled : l10n.disabled;

    final buffer = StringBuffer()
      ..writeln(l10n.settingsPageTitle)
      ..writeln('${l10n.serverAddress}: $serverAddress')
      ..writeln(l10n.accessibilitySectionTitle)
      ..writeln(
        '${l10n.colorBlindModeLabel}: $colorBlindStatus',
      )
      ..writeln(
        '${l10n.screenReaderLabel}: $screenReaderStatus',
      );

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection = Directionality.of(context);
    final messenger = ScaffoldMessenger.of(context);

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsReady &&
            state.message != null &&
            state.message!.isNotEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state is SettingsLoading) {
          return Scaffold(
            backgroundColor: AppColors.getBackgroundColor(context),
            appBar: AppBar(
              title: Text(
                l10n.settingsPageTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              centerTitle: false,
              elevation: 0,
              backgroundColor: AppColors.getSurfaceColor(context),
              surfaceTintColor: Colors.transparent,
            ),
            body: Center(
              child: Semantics(
                label: 'Loading settings',
                child: const CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (state is SettingsError) {
          return Scaffold(
            backgroundColor: AppColors.getBackgroundColor(context),
            appBar: AppBar(
              title: Text(
                l10n.settingsPageTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
              centerTitle: false,
              elevation: 0,
              backgroundColor: AppColors.getSurfaceColor(context),
              surfaceTintColor: Colors.transparent,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                      semanticLabel: 'Error',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      state.message,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final s = state as SettingsReady;
        _controller.value = _controller.value.copyWith(
          text: s.currentAddress,
          selection: TextSelection.collapsed(offset: s.currentAddress.length),
        );

        return Scaffold(
          backgroundColor: AppColors.getBackgroundColor(context),
          appBar: AppBar(
            title: Text(
              l10n.settingsPageTitle,
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
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              Semantics(
                label: l10n.closeAction,
                button: true,
                child: IconButton(
                  tooltip: l10n.closeAction,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final maxWidth = isWide ? 640.0 : double.infinity;
              final bottomInset = MediaQuery.of(context).padding.bottom;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg + bottomInset + 120,
                    ),
                    children: [
                      Card(
                        elevation: 2,
                        shadowColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : AppColors.gray300.withValues(alpha: 0.2),
                        color: AppColors.getSurfaceColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: AppColors.getBorderColor(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.dns_rounded,
                                      size: 24,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        l10n.serverAddress,
                                        style: AppTypography.headlineMedium
                                            .copyWith(
                                              color:
                                                  AppColors.getTextPrimaryColor(
                                                    context,
                                                  ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                label: 'Server address field',
                                child: TextFormField(
                                  controller: _controller,
                                  keyboardType: TextInputType.url,
                                  onChanged: context
                                      .read<SettingsCubit>()
                                      .onAddressChanged,
                                  style: AppTypography.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: l10n.serverAddressHint,
                                    hintStyle: AppTypography.bodyMedium
                                        .copyWith(
                                          color: AppColors.getTextTertiaryColor(
                                            context,
                                          ),
                                        ),
                                    prefixIcon: Icon(
                                      Icons.link_rounded,
                                      color: AppColors.primary,
                                    ),
                                    errorText: s.isValid
                                        ? null
                                        : l10n.invalidUrl,
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
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: AppColors.error,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.md,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.md,
                                children: [
                                  Semantics(
                                    label: '${l10n.saveServerAddress} button',
                                    button: true,
                                    child: FilledButton.icon(
                                      onPressed: s.isValid && s.isDirty
                                          ? context.read<SettingsCubit>().save
                                          : null,
                                      icon: const Icon(
                                        Icons.save_rounded,
                                        size: 20,
                                      ),
                                      label: Text(
                                        l10n.saveServerAddress,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        disabledBackgroundColor: AppColors
                                            .primary
                                            .withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Semantics(
                                    label: '${l10n.reloadServer} button',
                                    button: true,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          context.read<SettingsCubit>().save,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                      ),
                                      label: Text(
                                        l10n.reloadServer,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        elevation: 2,
                        shadowColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : AppColors.gray300.withValues(alpha: 0.2),
                        color: AppColors.getSurfaceColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: AppColors.getBorderColor(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.visibility_outlined,
                                      size: 24,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        l10n.accessibilitySectionTitle,
                                        style: AppTypography.headlineMedium
                                            .copyWith(
                                              color:
                                                  AppColors.getTextPrimaryColor(
                                                    context,
                                                  ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.accessibilitySectionDescription,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.colorBlindModeLabel,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextPrimaryColor(
                                      context,
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  l10n.colorBlindModeDescription,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.getTextSecondaryColor(
                                      context,
                                    ),
                                  ),
                                ),
                                value: s.isColorBlindModeEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (value) async {
                                  final message = value
                                      ? l10n.colorBlindModeEnabled
                                      : l10n.colorBlindModeDisabled;
                                  await context
                                      .read<SettingsCubit>()
                                      .onColorBlindModeChanged(
                                        value,
                                        feedbackMessage: message,
                                        textDirection: textDirection,
                                      );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                },
                              ),
                              const Divider(),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.screenReaderLabel,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextPrimaryColor(
                                      context,
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  l10n.screenReaderDescription,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.getTextSecondaryColor(
                                      context,
                                    ),
                                  ),
                                ),
                                value: s.isScreenReaderEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (value) async {
                                  final message = value
                                      ? l10n.screenReaderEnabledMessage
                                      : l10n.screenReaderDisabledMessage;
                                  await context
                                      .read<SettingsCubit>()
                                      .onScreenReaderChanged(
                                        value,
                                        feedbackMessage: message,
                                        textDirection: textDirection,
                                      );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                },
                              ),
                              if (s.isScreenReaderEnabled)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.sm,
                                    ),
                                    child: OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.volume_up_rounded,
                                        size: 20,
                                      ),
                                      label: Text(
                                        l10n.readScreenButtonLabel,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      onPressed: () async {
                                        final summary = _buildScreenSummary(
                                          l10n,
                                          s,
                                        );
                                        await context.read<SettingsCubit>()
                                            .readCurrentScreen(
                                          summary,
                                          textDirection: textDirection,
                                        );
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.readScreenInProgress,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        elevation: 2,
                        shadowColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : AppColors.gray300.withValues(alpha: 0.2),
                        color: AppColors.getSurfaceColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: AppColors.getBorderColor(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.aboutSection,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.getTextPrimaryColor(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      l10n.clientVersionInfo,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.getTextSecondaryColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: bottomInset + 24),
                    ],
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
