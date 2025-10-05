import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback pour gérer les URLs OAuth
  Function(String provider, String code)? onOAuthCallback;
  Function(String error)? onOAuthError;

  Future<void> initialize() async {
    try {
      // Listen for incoming deep links
      _linkSubscription = _appLinks.uriLinkStream.listen(
            (Uri uri) {
          debugPrint('🔗 Deep link received: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('❌ Deep link error: $err');
        },
      );

      // Check if there's an initial link when app launches
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🚀 Initial deep link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('❌ Deep link initialization error: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔍 Processing deep link: ${uri.toString()}');

    // Check if it's an OAuth callback
    if (uri.path.startsWith('/oauth/') && uri.path.contains('/callback')) {
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'oauth' &&
          pathSegments[2] == 'callback') {

        final provider = pathSegments[1]; // google, facebook, apple
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];

        debugPrint('🔄 OAuth callback detected - Provider: $provider');

        if (error != null) {
          debugPrint('❌ OAuth error: $error');
          onOAuthError?.call(error);
        } else if (code != null) {
          debugPrint('✅ OAuth code received: ${code.substring(0, 10)}...');
          onOAuthCallback?.call(provider, code);
        } else {
          debugPrint('❌ OAuth without code or error');
          onOAuthError?.call('No authorization code received');
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    onOAuthCallback = null;
    onOAuthError = null;
  }
}