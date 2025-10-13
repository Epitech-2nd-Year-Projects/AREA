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

    _deepLinkService.addOAuthCallbackListener(_handleOAuthCallback);
    _deepLinkService.addOAuthErrorListener(_handleOAuthError);

    _deepLinkService.initialize();
  }

  Future<String> startOAuth(OAuthProvider provider, {String? returnTo}) async {
    try {
      debugPrint('🚀 Starting OAuth for $provider');

      final response = await _oauthDataSource.startOAuthFlow(provider, null);

      final uri = Uri.parse(response.authorizationUrl);
      final redirectUri = uri.queryParameters['redirect_uri'];

      _flowData[provider] = _OAuthFlowData(
        codeVerifier: response.codeVerifier,
        redirectUri: redirectUri,
        state: response.state,
        returnTo: returnTo,
      );

      debugPrint('📝 Stored OAuth data for $provider');

      String finalUrl = response.authorizationUrl;
      if (returnTo != null) {
        final authUri = Uri.parse(response.authorizationUrl);
        final modifiedUri = authUri.replace(
          queryParameters: {
            ...authUri.queryParameters,
            'returnTo': returnTo,
          },
        );
        finalUrl = modifiedUri.toString();
      }

      return finalUrl;
    } catch (e) {
      debugPrint('❌ OAuth start error: $e');
      rethrow;
    }
  }

  void _handleOAuthCallback(
      String providerStr,
      String code,
      String? state,
      String? returnTo,
      ) async {
    try {
      debugPrint('🔄 Processing OAuth callback: $providerStr');

      final provider = _parseProvider(providerStr);
      if (provider == null) {
        _handleOAuthError(providerStr, 'Unsupported provider: $providerStr');
        return;
      }

      final data = _flowData[provider];
      if (data == null) {
        debugPrint('⚠️ No OAuth flow data found for $provider');
        _handleOAuthError(providerStr, 'OAuth session expired. Please try again.');
        return;
      }

      debugPrint('🔑 Using stored OAuth data:');

      final session = await _completeOAuthLogin(
        provider,
        code,
        data.codeVerifier,
        data.redirectUri,
        data.state ?? state,
      );

      debugPrint('✅ OAuth successful for: ${session.user.email}');

      _flowData.remove(provider);

      onSuccess?.call(session.user);
    } catch (e) {
      debugPrint('❌ OAuth callback error: $e');
      _flowData.remove(_parseProvider(providerStr));
      _handleOAuthError(providerStr, e.toString());
    }
  }

  void _handleOAuthError(String? provider, String error) {
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
    _deepLinkService.removeOAuthCallbackListener(_handleOAuthCallback);
    _deepLinkService.removeOAuthErrorListener(_handleOAuthError);
    _flowData.clear();
    onSuccess = null;
    onError = null;
  }
}

class _OAuthFlowData {
  final String? codeVerifier;
  final String? redirectUri;
  final String? state;
  final String? returnTo;

  _OAuthFlowData({
    this.codeVerifier,
    this.redirectUri,
    this.state,
    this.returnTo,
  });
}