import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/oauth_provider.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../../domain/value_objects/oauth_redirect_url.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(Email email, Password password) async {
    // TODO: implement API call with Dio
    throw UnimplementedError();
  }

  @override
  Future<User> register(Email email, Password password) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<OAuthRedirectUrl> startOAuthLogin(OAuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> completeOAuthLogin(OAuthProvider provider, String callbackCode) async {
    throw UnimplementedError();
  }

  @override
  Future<User> getCurrentUser() async {
    throw UnimplementedError();
  }
}