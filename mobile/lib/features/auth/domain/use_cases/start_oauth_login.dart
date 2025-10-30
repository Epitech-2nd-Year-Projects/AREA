import '../../../../core/network/api_config.dart';
import '../entities/oauth_provider.dart';
import '../value_objects/oauth_redirect_url.dart';
import '../repositories/auth_repository.dart';

class StartOAuthLogin {
  final AuthRepository repository;

  StartOAuthLogin(this.repository);

  Future<OAuthRedirectUrl> call(OAuthProvider provider) async {
    final redirectUri = ApiConfig.getOAuthCallbackUrl(provider.slug);
    return await repository.startOAuthLogin(provider, redirectUri);
  }
}
