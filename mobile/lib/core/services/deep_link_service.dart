import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  final Set<String> _processedCodes = {};
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  GoRouter? _router;

  final List<void Function(String provider, String code, String? state, String? returnTo)>
  _oauthCallbackListeners = [];
  final List<void Function(String? provider, String error)>
  _oauthErrorListeners = [];

  final List<void Function(String provider, String code, String? state)>
  _serviceCallbackListeners = [];
  final List<void Function(String? provider, String error)>
  _serviceErrorListeners = [];

  void setRouter(GoRouter router) {
    _router = router;
  }

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ DeepLinkService already initialized');
      return;
    }
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

    if (uri.scheme == 'area') {
      _handleAreaScheme(uri);
      return;
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      _handleHttpCallback(uri);
    }
  }

  void _handleAreaScheme(Uri uri) {
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 3 && pathSegments[2] == 'callback') {
      final type = pathSegments[0];
      final provider = pathSegments[1];
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final state = uri.queryParameters['state'];
      final returnTo = uri.queryParameters['returnTo'];

      debugPrint('🔄 Custom scheme callback - Type: $type, Provider: $provider');

      if (type == 'services') {
        if (error != null) {
          for (final listener in List.of(_serviceErrorListeners)) {
            listener(provider, error);
          }
        } else if (code != null) {
          for (final listener in List.of(_serviceCallbackListeners)) {
            listener(provider, code, state);
          }
        }

        if (_router != null && code != null) {
          _router!.go(
            '/services/$provider/callback?code=$code${state != null ? '&state=$state' : ''}',
          );
        }
      } else {
        if (error != null) {
          for (final listener in List.of(_oauthErrorListeners)) {
            listener(provider, error);
          }
        } else if (code != null) {
          for (final listener in List.of(_oauthCallbackListeners)) {
            listener(provider, code, state, returnTo);
          }
        }

        if (_router != null && code != null) {
          _router!.go(
            '/oauth/$provider/callback?code=$code${state != null ? '&state=$state' : ''}${returnTo != null ? '&returnTo=$returnTo' : ''}',
          );
        }
      }
    }
  }

  void _handleHttpCallback(Uri uri) {
    if (uri.path.startsWith('/oauth/') && uri.path.contains('/callback')) {
      _processOAuthCallback(uri, 'oauth');
    } else if (uri.path.startsWith('/services/') && uri.path.contains('/callback')) {
      _processServiceCallback(uri, 'services');
    }
  }

  void _processOAuthCallback(Uri uri, String type) {
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 3 && pathSegments[2] == 'callback') {
      final provider = pathSegments[1];
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final state = uri.queryParameters['state'];
      final returnTo = uri.queryParameters['returnTo'];

      if (code != null && _processedCodes.contains(code)) {
        debugPrint('⏭️ Ignoring duplicate callback for code: ${code.substring(0, 10)}...');
        return;
      }

      if (code != null) {
        _processedCodes.add(code);
      }

      debugPrint('🔄 HTTP callback - Type: $type, Provider: $provider');

      if (error != null) {
        debugPrint('❌ OAuth error: $error');
        for (final listener in List.of(_oauthErrorListeners)) {
          listener(provider, error);
        }
      } else if (code != null) {
        debugPrint('✅ OAuth code received');
        for (final listener in List.of(_oauthCallbackListeners)) {
          listener(provider, code, state, returnTo);
        }
      }
    }
  }

  void _processServiceCallback(Uri uri, String type) {
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 3 && pathSegments[2] == 'callback') {
      final provider = pathSegments[1];
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final state = uri.queryParameters['state'];

      if (code != null && _processedCodes.contains(code)) {
        debugPrint('⏭️ Ignoring duplicate service callback');
        return;
      }

      if (code != null) {
        _processedCodes.add(code);
      }

      debugPrint('🔄 HTTP service callback - Provider: $provider');

      if (error != null) {
        debugPrint('❌ Service error: $error');
        for (final listener in List.of(_serviceErrorListeners)) {
          listener(provider, error);
        }
      } else if (code != null) {
        debugPrint('✅ Service code received');
        for (final listener in List.of(_serviceCallbackListeners)) {
          listener(provider, code, state);
        }
      }
    }
  }

  @visibleForTesting
  void handleDeepLinkForTest(Uri uri) => _handleDeepLink(uri);

  void dispose() {
    _linkSubscription?.cancel();
    _oauthCallbackListeners.clear();
    _oauthErrorListeners.clear();
    _serviceCallbackListeners.clear();
    _serviceErrorListeners.clear();
    _processedCodes.clear();
    _initialized = false;
  }

  void addOAuthCallbackListener(
      void Function(String provider, String code, String? state, String? returnTo)
      listener) {
    _oauthCallbackListeners.add(listener);
  }

  void removeOAuthCallbackListener(
      void Function(String provider, String code, String? state, String? returnTo)
      listener) {
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

  void addServiceCallbackListener(
      void Function(String provider, String code, String? state) listener) {
    _serviceCallbackListeners.add(listener);
  }

  void removeServiceCallbackListener(
      void Function(String provider, String code, String? state) listener) {
    _serviceCallbackListeners.remove(listener);
  }

  void addServiceErrorListener(
      void Function(String? provider, String error) listener) {
    _serviceErrorListeners.add(listener);
  }

  void removeServiceErrorListener(
      void Function(String? provider, String error) listener) {
    _serviceErrorListeners.remove(listener);
  }
}