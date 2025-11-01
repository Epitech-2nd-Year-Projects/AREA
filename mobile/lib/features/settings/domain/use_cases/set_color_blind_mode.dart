import '../repositories/settings_repository.dart';

class SetColorBlindMode {
  final SettingsRepository _repository;

  SetColorBlindMode(this._repository);

  Future<void> call(bool enabled) => _repository.setColorBlindMode(enabled);
}
