import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  final List<void Function(String provider, String code, String? state, String? returnTo)>
  _oauthCallbackListeners = [];
  final List<void Function(String? provider, String error)>
  _oauthErrorListeners = [];

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen(
            (Uri uri) {
          debugPrint('🔗 Deep link received: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('❌ Deep link error: $err');
        },
      );

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

    if (uri.path.startsWith('/oauth/') && uri.path.contains('/callback')) {
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'oauth' &&
          pathSegments[2] == 'callback') {

        final provider = pathSegments[1];
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];
        final state = uri.queryParameters['state'];
        final returnTo = uri.queryParameters['returnTo'];

        debugPrint('🔄 OAuth callback detected - Provider: $provider');

        if (error != null) {
          debugPrint('❌ OAuth error: $error');
          for (final listener in List.of(_oauthErrorListeners)) {
            listener(provider, error);
          }
        } else if (code != null) {
          debugPrint('✅ OAuth code received: ${code.substring(0, 10)}...');
          for (final listener in List.of(_oauthCallbackListeners)) {
            listener(provider, code, state, returnTo);
          }
        } else {
          debugPrint('❌ OAuth without code or error');
          for (final listener in List.of(_oauthErrorListeners)) {
            listener(provider, 'No authorization code received');
          }
        }
      }
    }
    if (uri.path.startsWith('/services/') && uri.path.contains('/callback')) {
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'services' &&
          pathSegments[2] == 'callback') {

        final provider = pathSegments[1];
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];
        final state = uri.queryParameters['state'];
        final returnTo = uri.queryParameters['returnTo'];

        debugPrint('🔄 OAuth callback detected - Provider: $provider');

        if (error != null) {
          debugPrint('❌ OAuth error: $error');
          for (final listener in List.of(_oauthErrorListeners)) {
            listener(provider, error);
          }
        } else if (code != null) {
          debugPrint('✅ OAuth code received: ${code.substring(0, 10)}...');
          for (final listener in List.of(_oauthCallbackListeners)) {
            listener(provider, code, state, returnTo);
          }
        } else {
          debugPrint('❌ OAuth without code or error');
          for (final listener in List.of(_oauthErrorListeners)) {
            listener(provider, 'No authorization code received');
          }
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _oauthCallbackListeners.clear();
    _oauthErrorListeners.clear();
    _initialized = false;
  }

  void addOAuthCallbackListener(
      void Function(String provider, String code, String? state, String? returnTo) listener,) {
    _oauthCallbackListeners.add(listener);
  }

  void removeOAuthCallbackListener(
      void Function(String provider, String code, String? state, String? returnTo) listener,) {
    _oauthCallbackListeners.remove(listener);
  }

  void addOAuthErrorListener(
      void Function(String? provider, String error) listener) {
    _oauthErrorListeners.add(listener);
  }

  void removeOAuthErrorListener(
      void Function(String? provider, String error) listener) {
    _oauthErrorListeners.remove(listener);
  }
}
