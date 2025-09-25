import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';


abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class UserLoggedIn extends AuthEvent {
  final User user;
  const UserLoggedIn(this.user);

  @override
  List<Object> get props => [user];
}

class UserLoggedOut extends AuthEvent {}

class SessionExpired extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}