import '../repositories/settings_repository.dart';

class GetServerAddress {
  final SettingsRepository _repo;
  GetServerAddress(this._repo);

  String call() => _repo.getServerAddress();
}
