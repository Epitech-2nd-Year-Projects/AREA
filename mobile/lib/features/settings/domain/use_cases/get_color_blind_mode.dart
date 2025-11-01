import '../repositories/settings_repository.dart';

class GetColorBlindMode {
  final SettingsRepository _repository;

  GetColorBlindMode(this._repository);

  bool call() => _repository.getColorBlindMode();
}
