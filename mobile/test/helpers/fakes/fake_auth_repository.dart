import 'package:area/features/auth/domain/entities/auth_session.dart';
import 'package:area/features/auth/domain/entities/oauth_provider.dart';
import 'package:area/features/auth/domain/entities/user.dart';
import 'package:area/features/auth/domain/repositories/auth_repository.dart';
import 'package:area/features/auth/domain/value_objects/email.dart';
import 'package:area/features/auth/domain/value_objects/oauth_redirect_url.dart';
import 'package:area/features/auth/domain/value_objects/password.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> completeOAuthLogin(
    OAuthProvider provider,
    String callbackCode,
    String? codeVerifier,
    String? redirectUri,
    String? state,
  ) =>
      Future.error(UnimplementedError());

  @override
  Future<User> getCurrentUser() => Future.error(UnimplementedError());

  @override
  Future<User> login(Email email, Password password) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() => Future.value();

  @override
  Future<User> register(Email email, Password password) =>
      Future.error(UnimplementedError());

  @override
  Future<OAuthRedirectUrl> startOAuthLogin(
    OAuthProvider provider,
    String? redirectUri,
  ) =>
      Future.error(UnimplementedError());

  @override
  Future<User> verifyEmail(String token) => Future.error(UnimplementedError());
}
