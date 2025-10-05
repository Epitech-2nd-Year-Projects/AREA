import 'package:equatable/equatable.dart';
import '../../../domain/entities/oauth_provider.dart';
import '../../../domain/entities/user.dart'; // Changé pour User au lieu de AuthSession

abstract class OAuthState extends Equatable {
  const OAuthState();

  @override
  List<Object?> get props => [];
}

class OAuthInitial extends OAuthState {}

class OAuthStarting extends OAuthState {
  final OAuthProvider provider;
  const OAuthStarting(this.provider);

  @override
  List<Object?> get props => [provider];
}

class OAuthWaitingForCallback extends OAuthState {
  final OAuthProvider provider;
  const OAuthWaitingForCallback(this.provider);

  @override
  List<Object?> get props => [provider];
}

class OAuthSuccess extends OAuthState {
  final User user; // Changé pour User
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

class OAuthRedirectReady extends OAuthState {
  final OAuthProvider provider;
  final String redirectUrl;

  const OAuthRedirectReady(this.provider, this.redirectUrl);

  @override
  List<Object?> get props => [provider, redirectUrl];
}

class OAuthCallbackReceived extends OAuthState {
  final OAuthProvider provider;
  final String callbackCode;

  const OAuthCallbackReceived(this.provider, this.callbackCode);

  @override
  List<Object?> get props => [provider, callbackCode];
}