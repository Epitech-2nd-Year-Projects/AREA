import 'package:equatable/equatable.dart';
import '../../../domain/entities/oauth_provider.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/value_objects/oauth_redirect_url.dart';

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

class OAuthRedirectReady extends OAuthState {
  final OAuthProvider provider;
  final OAuthRedirectUrl redirectUrl;

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

class OAuthSuccess extends OAuthState {
  final AuthSession session;
  const OAuthSuccess(this.session);

  @override
  List<Object?> get props => [session];
}

class OAuthError extends OAuthState {
  final String message;
  const OAuthError(this.message);

  @override
  List<Object?> get props => [message];
}