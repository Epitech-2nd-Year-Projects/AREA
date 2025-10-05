import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsReady extends SettingsState {
  final String currentAddress;
  final bool isDirty;
  final bool isValid;
  final String? message;

  const SettingsReady({
    required this.currentAddress,
    required this.isDirty,
    required this.isValid,
    this.message,
  });

  SettingsReady copyWith({
    String? currentAddress,
    bool? isDirty,
    bool? isValid,
    String? message,
  }) {
    return SettingsReady(
      currentAddress: currentAddress ?? this.currentAddress,
      isDirty: isDirty ?? this.isDirty,
      isValid: isValid ?? this.isValid,
      message: message,
    );
  }

  @override
  List<Object?> get props => [currentAddress, isDirty, isValid, message];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}
