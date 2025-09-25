import '../entities/auth_session.dart';
import '../entities/oauth_provider.dart';
import '../repositories/auth_repository.dart';

class CompleteOAuthLogin {
  final AuthRepository repository;

  CompleteOAuthLogin(this.repository);

  Future<AuthSession> call(OAuthProvider provider, String callbackCode) async {
    return await repository.completeOAuthLogin(provider, callbackCode);
  }
}