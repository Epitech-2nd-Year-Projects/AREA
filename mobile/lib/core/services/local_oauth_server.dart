import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class LocalOAuthServer {
  static final LocalOAuthServer _instance = LocalOAuthServer._internal();
  factory LocalOAuthServer() => _instance;
  LocalOAuthServer._internal();

  HttpServer? _server;
  Completer<OAuthCallbackData>? _callbackCompleter;
  bool _isRunning = false;

  Future<void> start() async {
    if (_isRunning) {
      debugPrint('⚠️ Server already running');
      return;
    }

    try {
      final router = Router()
        ..get('/oauth/<provider>/callback', _handleOAuthCallback)
        ..get('/services/<provider>/callback', _handleServiceCallback);

      final handler = Pipeline()
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);

      _server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4,
        8080,
      );

      _isRunning = true;
      debugPrint('✅ Local OAuth server started on http://localhost:8080');
    } catch (e) {
      debugPrint('❌ Failed to start server: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _callbackCompleter = null;
    debugPrint('🛑 Local OAuth server stopped');
  }

  Future<OAuthCallbackData> waitForCallback() {
    _callbackCompleter = Completer<OAuthCallbackData>();
    return _callbackCompleter!.future;
  }

  Response _handleOAuthCallback(Request request, String provider) {
    return _handleCallback(request, provider, isService: false);
  }

  Response _handleServiceCallback(Request request, String provider) {
    return _handleCallback(request, provider, isService: true);
  }

  Response _handleCallback(
      Request request,
      String provider, {
        required bool isService,
      }) {
    final params = request.url.queryParameters;
    final code = params['code'];
    final error = params['error'];
    final state = params['state'];
    final returnTo = params['returnTo'];

    debugPrint('🔄 Callback received for $provider');
    debugPrint('   Code: ${code?.substring(0, 10)}...');
    debugPrint('   Error: $error');
    debugPrint('   State: $state');

    final callbackData = OAuthCallbackData(
      provider: provider,
      code: code,
      error: error,
      state: state,
      returnTo: returnTo,
      isService: isService,
    );

    _callbackCompleter?.complete(callbackData);
    _callbackCompleter = null;

    final callbackType = isService ? 'services' : 'oauth';
    final customSchemeUrl = _buildCustomSchemeUrl(
      callbackType,
      provider,
      code,
      error,
      state,
      returnTo,
    );

    return Response.ok(
      _buildSuccessHtml(customSchemeUrl),
      headers: {
        'Content-Type': 'text/html',
        'Cache-Control': 'no-cache',
      },
    );
  }

  String _buildCustomSchemeUrl(
      String type,
      String provider,
      String? code,
      String? error,
      String? state,
      String? returnTo,
      ) {
    final params = <String, String>{};
    if (code != null) params['code'] = code;
    if (error != null) params['error'] = error;
    if (state != null) params['state'] = state;
    if (returnTo != null) params['returnTo'] = returnTo;

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return 'area://$type/$provider/callback${query.isNotEmpty ? '?$query' : ''}';
  }

  String _buildSuccessHtml(String customSchemeUrl) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Authentication Successful</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .container {
      background: white;
      padding: 2rem;
      border-radius: 1rem;
      box-shadow: 0 10px 40px rgba(0,0,0,0.1);
      text-align: center;
      max-width: 400px;
    }
    h1 { color: #667eea; margin-bottom: 1rem; }
    p { color: #666; line-height: 1.6; }
    .checkmark {
      font-size: 4rem;
      color: #4CAF50;
      margin-bottom: 1rem;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="checkmark">✓</div>
    <h1>Authentication Successful!</h1>
    <p>You will be redirected to the app automatically...</p>
    <p style="font-size: 0.9rem; color: #999; margin-top: 1.5rem;">
      If nothing happens, you can safely close this window.
    </p>
  </div>
  
  <script>
    window.location.href = '$customSchemeUrl';
    
    setTimeout(function() {
      window.close();
    }, 2000);
    
    let attempts = 0;
    const maxAttempts = 3;
    const interval = setInterval(function() {
      if (attempts >= maxAttempts) {
        clearInterval(interval);
        return;
      }
      window.location.href = '$customSchemeUrl';
      attempts++;
    }, 500);
  </script>
</body>
</html>
    ''';
  }

  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }

        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  final Map<String, String> _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}

class OAuthCallbackData {
  final String provider;
  final String? code;
  final String? error;
  final String? state;
  final String? returnTo;
  final bool isService;

  const OAuthCallbackData({
    required this.provider,
    this.code,
    this.error,
    this.state,
    this.returnTo,
    required this.isService,
  });

  bool get hasError => error != null;
  bool get hasCode => code != null;
}