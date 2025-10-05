import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_server_address.dart';
import '../../domain/use_cases/set_server_address.dart';
import '../../domain/use_cases/probe_server_address.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetServerAddress _getServerAddress;
  final SetServerAddress _setServerAddress;
  final ProbeServerAddress _probeServerAddress;

  String _initialAddress = '';

  SettingsCubit({
    required GetServerAddress getServerAddress,
    required SetServerAddress setServerAddress,
    required ProbeServerAddress probeServerAddress,
  })  : _getServerAddress = getServerAddress,
        _setServerAddress = setServerAddress,
        _probeServerAddress = probeServerAddress,
        super(const SettingsLoading());

  void load() {
    final addr = _getServerAddress();
    _initialAddress = addr;
    emit(SettingsReady(
      currentAddress: addr,
      isDirty: false,
      isValid: _isValidUrl(addr),
    ));
  }

  void onAddressChanged(String value) {
    final st = state;
    if (st is! SettingsReady) return;
    emit(st.copyWith(
      currentAddress: value,
      isDirty: value.trim() != _initialAddress.trim(),
      isValid: _isValidUrl(value),
      message: null,
    ));
  }

  Future<void> save() async {
    final st = state;
    if (st is! SettingsReady) return;

    final trimmed = st.currentAddress.trim();

    if (!_isValidUrl(trimmed)) {
      emit(st.copyWith(message: 'URL invalide. Exemple: https://api.example.com'));
      return;
    }

    final reachable = await _probeServerAddress(trimmed);
    if (!reachable) {
      emit(st.copyWith(message: 'Serveur injoignable. Vérifie l’URL ou ta connexion.'));
      return;
    }

    await _setServerAddress(trimmed);
    _initialAddress = trimmed;

    emit(st.copyWith(
      isDirty: false,
      isValid: true,
      message: 'Adresse serveur mise à jour.',
    ));
  }

  static bool _isValidUrl(String input) {
    final uri = Uri.tryParse(input);
    return uri != null && uri.hasScheme && uri.isAbsolute;
  }
}
