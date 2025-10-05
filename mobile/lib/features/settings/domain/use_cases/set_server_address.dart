import '../repositories/settings_repository.dart';

class SetServerAddress {
  final SettingsRepository _repo;
  SetServerAddress(this._repo);

  Future<void> call(String address) => _repo.setServerAddress(address);
}
