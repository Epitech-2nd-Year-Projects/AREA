import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../services/domain/entities/service_with_status.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;
  final String displayName;
  final List<ServiceWithStatus> services;
  List<ServiceWithStatus> get subscribedServices =>
    services.where((s) => s.isSubscribed).toList();

  const ProfileLoaded({
    required this.user,
    required this.displayName,
    required this.services,
  });

  @override
  List<Object?> get props => [user, displayName, services];

  ProfileLoaded copyWith({User? user, String? displayName, List<ServiceWithStatus>? services}) {
    return ProfileLoaded(
      user: user ?? this.user,
      displayName: displayName ?? this.displayName,
      services: services ?? this.services,
    );
  }
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
