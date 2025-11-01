import '../repositories/settings_repository.dart';

class SetScreenReaderEnabled {
  final SettingsRepository _repository;

  SetScreenReaderEnabled(this._repository);

  Future<void> call(bool enabled) =>
      _repository.setScreenReaderEnabled(enabled);
}
