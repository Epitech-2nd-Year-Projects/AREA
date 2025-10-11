import 'package:equatable/equatable.dart';

abstract class OAuthState extends Equatable {
  const OAuthState();

  @override
  List<Object?> get props => [];
}

class OAuthInitial extends OAuthState {}

class OAuthLoading extends OAuthState {}

class OAuthRedirectReady extends OAuthState {
  final String redirectUrl;
  final String? returnTo;

  const OAuthRedirectReady(this.redirectUrl, {this.returnTo});

  @override
  List<Object?> get props => [redirectUrl, returnTo];
}

class OAuthSuccess extends OAuthState {
  final dynamic user;

  const OAuthSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class OAuthError extends OAuthState {
  final String message;

  const OAuthError(this.message);

  @override
  List<Object?> get props => [message];
}