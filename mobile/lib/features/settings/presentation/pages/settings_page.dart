import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsReady && state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);

        if (state is SettingsLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.settingsPageTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SettingsError) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.settingsPageTitle)),
            body: Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
          );
        }

        final s = state as SettingsReady;
        _controller.value = _controller.value.copyWith(
          text: s.currentAddress,
          selection: TextSelection.collapsed(offset: s.currentAddress.length),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsPageTitle),
            actions: [
              IconButton(
                tooltip: l10n.closeAction,
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              )
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final maxWidth = isWide ? 640.0 : double.infinity;
              final border = OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.getBorderColor(context), width: 1.5),
              );

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 0,
                        color: AppColors.getSurfaceColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.getBorderColor(context)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.serverAddress, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _controller,
                                keyboardType: TextInputType.url,
                                onChanged: context.read<SettingsCubit>().onAddressChanged,
                                decoration: InputDecoration(
                                  hintText: l10n.serverAddressHint,
                                  prefixIcon: const Icon(Icons.link),
                                  errorText: s.isValid ? null : l10n.invalidUrl,
                                  border: border,
                                  enabledBorder: border,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  errorBorder: border,
                                  focusedErrorBorder: border,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: s.isValid && s.isDirty
                                        ? context.read<SettingsCubit>().save
                                        : null,
                                    icon: const Icon(Icons.save),
                                    label: Text(l10n.saveServerAddress),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => context.read<SettingsCubit>().save,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(l10n.reloadServer),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        color: AppColors.getSurfaceColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.getBorderColor(context)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l10n.aboutSection),
                          subtitle: Text(l10n.clientVersionInfo),
                        ),
                      ),
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
