import '../repositories/settings_repository.dart';

class GetScreenReaderEnabled {
  final SettingsRepository _repository;

  GetScreenReaderEnabled(this._repository);

  bool call() => _repository.getScreenReaderEnabled();
}
