import '../entities/user.dart';
import '../entities/auth_session.dart';
import '../entities/oauth_provider.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';
import '../value_objects/oauth_redirect_url.dart';

abstract class AuthRepository {
  Future<User> login(Email email, Password password);
  Future<User> register(Email email, Password password);
  Future<void> logout();
  Future<User> getCurrentUser();
  Future<User> verifyEmail(String token);

  Future<OAuthRedirectUrl> startOAuthLogin(OAuthProvider provider);
  Future<AuthSession> completeOAuthLogin(OAuthProvider provider,
      String callbackCode);
}