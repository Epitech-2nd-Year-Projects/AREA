import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/accessibility/accessibility_controller.dart';
import '../../domain/use_cases/get_server_address.dart';
import '../../domain/use_cases/set_server_address.dart';
import '../../domain/use_cases/probe_server_address.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetServerAddress _getServerAddress;
  final SetServerAddress _setServerAddress;
  final ProbeServerAddress _probeServerAddress;
  final AccessibilityController _accessibilityController;

  String _initialAddress = '';

  SettingsCubit({
    required GetServerAddress getServerAddress,
    required SetServerAddress setServerAddress,
    required ProbeServerAddress probeServerAddress,
    required AccessibilityController accessibilityController,
  }) : _getServerAddress = getServerAddress,
       _setServerAddress = setServerAddress,
       _probeServerAddress = probeServerAddress,
       _accessibilityController = accessibilityController,
       super(const SettingsLoading());

  void load() {
    final addr = _getServerAddress();
    _initialAddress = addr;
    emit(
      SettingsReady(
        currentAddress: addr,
        isDirty: false,
        isValid: _isValidUrl(addr),
        isColorBlindModeEnabled:
            _accessibilityController.isColorBlindModeEnabled,
        isScreenReaderEnabled:
            _accessibilityController.isScreenReaderEnabled,
      ),
    );
  }

  void onAddressChanged(String value) {
    final st = state;
    if (st is! SettingsReady) return;
    emit(
      st.copyWith(
        currentAddress: value,
        isDirty: value.trim() != _initialAddress.trim(),
        isValid: _isValidUrl(value),
        message: null,
      ),
    );
  }

  Future<void> onColorBlindModeChanged(
    bool enabled, {
    String? feedbackMessage,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    final st = state;
    if (st is! SettingsReady) return;
    await _accessibilityController.updateColorBlindMode(enabled);
    if (feedbackMessage != null) {
      await _accessibilityController.announce(
        feedbackMessage,
        textDirection: textDirection,
      );
    }
    emit(
      st.copyWith(
        isColorBlindModeEnabled: enabled,
        message: null,
      ),
    );
  }

  Future<void> onScreenReaderChanged(
    bool enabled, {
    String? feedbackMessage,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    final st = state;
    if (st is! SettingsReady) return;
    await _accessibilityController.updateScreenReaderEnabled(
      enabled,
      feedbackMessage: feedbackMessage,
      textDirection: textDirection,
    );
    emit(
      st.copyWith(
        isScreenReaderEnabled: enabled,
        message: null,
      ),
    );
  }

  Future<void> readCurrentScreen(
    String message, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return _accessibilityController.announce(
      message,
      textDirection: textDirection,
    );
  }

  Future<void> save() async {
    final st = state;
    if (st is! SettingsReady) return;

    final trimmed = st.currentAddress.trim();

    if (!_isValidUrl(trimmed)) {
      emit(
        st.copyWith(message: 'invalid URL. Exemple: https://api.example.com'),
      );
      return;
    }

    final reachable = await _probeServerAddress(trimmed);
    if (!reachable) {
      emit(st.copyWith(message: 'Server not accessible. Check server URL'));
      return;
    }

    await _setServerAddress(trimmed);
    _initialAddress = trimmed;

    emit(
      st.copyWith(
        isDirty: false,
        isValid: true,
        message: 'Server adress updated',
      ),
    );
  }

  static bool _isValidUrl(String input) {
    final uri = Uri.tryParse(input);
    return uri != null && uri.hasScheme && uri.isAbsolute;
  }
}
