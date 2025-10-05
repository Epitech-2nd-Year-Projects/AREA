import 'package:flutter/foundation.dart';
import '../../features/auth/domain/entities/oauth_provider.dart';
import '../../features/auth/domain/use_cases/start_oauth_login.dart';
import '../../features/auth/domain/use_cases/complete_oauth_login.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/datasources/oauth_remote_datasource.dart';
import 'deep_link_service.dart';

class OAuthManager {
  static final OAuthManager _instance = OAuthManager._internal();
  factory OAuthManager() => _instance;
  OAuthManager._internal();

  late final StartOAuthLogin _startOAuthLogin;
  late final CompleteOAuthLogin _completeOAuthLogin;
  late final DeepLinkService _deepLinkService;
  late final OAuthRemoteDataSource _oauthDataSource;

  final Map<OAuthProvider, _OAuthFlowData> _flowData = {};

  Function(dynamic user)? onSuccess;
  Function(String error)? onError;

  void initialize(
      AuthRepository repository,
      OAuthRemoteDataSource oauthDataSource,
      ) {
    _startOAuthLogin = StartOAuthLogin(repository);
    _completeOAuthLogin = CompleteOAuthLogin(repository);
    _oauthDataSource = oauthDataSource;
    _deepLinkService = DeepLinkService();

    _deepLinkService.onOAuthCallback = _handleOAuthCallback;
    _deepLinkService.onOAuthError = _handleOAuthError;

    _deepLinkService.initialize();
  }

  Future<String> startOAuth(OAuthProvider provider) async {
    try {
      debugPrint('🚀 Starting OAuth for $provider');

      final response = await _oauthDataSource.startOAuthFlow(provider, null);

      final uri = Uri.parse(response.authorizationUrl);
      final redirectUri = uri.queryParameters['redirect_uri'];

      _flowData[provider] = _OAuthFlowData(
        codeVerifier: response.codeVerifier,
        redirectUri: redirectUri,
        state: response.state,
      );

      debugPrint('📝 Stored OAuth data for $provider');
      debugPrint('   - code_verifier: ${response.codeVerifier != null ? "✓" : "✗"}');
      debugPrint('   - redirect_uri: $redirectUri');
      debugPrint('   - state: ${response.state}');


      return response.authorizationUrl;
    } catch (e) {
      debugPrint('❌ OAuth start error: $e');
      rethrow;
    }
  }

  void _handleOAuthCallback(String providerStr, String code) async {
    try {
      debugPrint('🔄 Processing OAuth callback: $providerStr');

      final provider = _parseProvider(providerStr);
      if (provider == null) {
        _handleOAuthError('Unsupported provider: $providerStr');
        return;
      }

      // Récupérer les données stockées
      final data = _flowData[provider];
      if (data == null) {
        debugPrint('⚠️ No OAuth flow data found for $provider');
        _handleOAuthError('OAuth session expired. Please try again.');
        return;
      }

      debugPrint('🔑 Using stored OAuth data:');
      debugPrint('   - code_verifier: ${data.codeVerifier != null ? "✓" : "✗"}');
      debugPrint('   - redirect_uri: ${data.redirectUri}');
      debugPrint('   - state: ${data.state}');

      final session = await _completeOAuthLogin(
        provider,
        code,
        data.codeVerifier,
        data.redirectUri,
        data.state,
      );

      debugPrint('✅ OAuth successful for: ${session.user.email}');

      _flowData.remove(provider);

      onSuccess?.call(session.user);
    } catch (e) {
      debugPrint('❌ OAuth callback error: $e');
      _flowData.remove(_parseProvider(providerStr));
      _handleOAuthError(e.toString());
    }
  }

  void _handleOAuthError(String error) {
    debugPrint('❌ OAuth error: $error');
    onError?.call(error);
  }

  OAuthProvider? _parseProvider(String providerString) {
    switch (providerString.toLowerCase()) {
      case 'google':
        return OAuthProvider.google;
      case 'facebook':
        return OAuthProvider.facebook;
      case 'apple':
        return OAuthProvider.apple;
      default:
        return null;
    }
  }

  void dispose() {
    _deepLinkService.dispose();
    _flowData.clear();
    onSuccess = null;
    onError = null;
  }
}

class _OAuthFlowData {
  final String? codeVerifier;
  final String? redirectUri;
  final String? state;

  _OAuthFlowData({
    this.codeVerifier,
    this.redirectUri,
    this.state,
  });
}