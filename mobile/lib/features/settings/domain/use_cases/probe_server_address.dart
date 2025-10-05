import '../repositories/settings_repository.dart';

class ProbeServerAddress {
  final SettingsRepository _repo;
  ProbeServerAddress(this._repo);

  Future<bool> call(String address) => _repo.probeServerAddress(address);
}
